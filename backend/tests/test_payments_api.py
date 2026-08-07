import pytest
from unittest.mock import AsyncMock, patch, MagicMock
from uuid import uuid4
from datetime import datetime, timezone

from app.schemas.payments import STKPushRequest, BambaStackCallbackPayload
from app.services.payment_service import PaymentService
from app.schemas.rides import RideResponse
from app.domain.exceptions import RuleViolationError, UnauthorizedError, ResourceNotFoundError

# ===========================================================================
# FIXTURES
# ===========================================================================

@pytest.fixture
def mock_deps():
    payment_repo = AsyncMock()
    ride_repo = AsyncMock()
    user_repo = AsyncMock()
    bambastack_client = AsyncMock()
    pubsub_service = AsyncMock()
    return payment_repo, ride_repo, user_repo, bambastack_client, pubsub_service

@pytest.fixture
def payment_service(mock_deps):
    p_repo, r_repo, u_repo, bambastack, pubsub = mock_deps
    return PaymentService(
        payment_repo=p_repo,
        ride_repo=r_repo,
        user_repo=u_repo,
        bambastack_client=bambastack,
        pubsub_service=pubsub
    )


# ===========================================================================
# 1. STK PUSH INITIATION — BAMBASTACK
# ===========================================================================

@pytest.mark.asyncio
async def test_stk_push_success(payment_service, mock_deps):
    """Successful STK Push via BambaStack returns transaction_id."""
    p_repo, r_repo, u_repo, bambastack, pubsub = mock_deps
    passenger_id = uuid4()
    ride_id = uuid4()

    r_repo.get_ride.return_value = RideResponse(
        id=ride_id, passenger_id=passenger_id, rider_id=None, status="FARE_ACCEPTED",
        payment_status="PENDING", version=1, created_at=datetime.now(timezone.utc), updated_at=datetime.now(timezone.utc)
    )
    p_repo.get_default_active_payment_account.return_value = {
        "id": str(uuid4()), "provider": "MPESA_TILL", "display_name": "7s Voi Till",
        "till_paybill_or_number": "123456", "is_default": True, "status": "active"
    }
    u_repo.get_user_by_id.return_value = {"id": str(passenger_id), "phone_number": "254712345678", "role": "PASSENGER"}

    conn_mock = AsyncMock()
    conn_mock.fetchrow.return_value = {"fare_amount": 350.0}
    pool_mock = MagicMock()
    pool_mock.acquire.return_value.__aenter__.return_value = conn_mock
    r_repo._get_pool.return_value = pool_mock

    bambastack.send_stk_push.return_value = {
        "transaction_id": "trx-bamba-001",
        "checkout_request_id": "chk-bamba-001"
    }

    payload = STKPushRequest(ride_id=ride_id)
    res = await payment_service.initiate_stk_push(passenger_id=passenger_id, payload=payload)

    assert res.transaction_id == "trx-bamba-001"
    assert res.checkout_request_id == "chk-bamba-001"
    bambastack.send_stk_push.assert_called_once()
    p_repo.insert_payment_event.assert_called_once()


@pytest.mark.asyncio
async def test_stk_push_no_payment_account_gating(payment_service, mock_deps):
    """BR-010: STK push rejected when no active payment account configured."""
    p_repo, r_repo, u_repo, bambastack, pubsub = mock_deps
    passenger_id = uuid4()
    ride_id = uuid4()

    r_repo.get_ride.return_value = RideResponse(
        id=ride_id, passenger_id=passenger_id, rider_id=None, status="FARE_SENT",
        payment_status="PENDING", version=1, created_at=datetime.now(timezone.utc), updated_at=datetime.now(timezone.utc)
    )
    p_repo.get_default_active_payment_account.return_value = None

    payload = STKPushRequest(ride_id=ride_id)
    with pytest.raises(RuleViolationError) as exc_info:
        await payment_service.initiate_stk_push(passenger_id=passenger_id, payload=payload)

    assert "M-PESA payments are currently unavailable" in str(exc_info.value)
    bambastack.send_stk_push.assert_not_called()


@pytest.mark.asyncio
async def test_stk_push_already_paid(payment_service, mock_deps):
    """BR-035: STK push rejected when ride payment already succeeded."""
    p_repo, r_repo, u_repo, bambastack, pubsub = mock_deps
    passenger_id = uuid4()
    ride_id = uuid4()

    r_repo.get_ride.return_value = RideResponse(
        id=ride_id, passenger_id=passenger_id, rider_id=None, status="COMPLETED",
        payment_status="SUCCESS", version=2, created_at=datetime.now(timezone.utc), updated_at=datetime.now(timezone.utc)
    )

    payload = STKPushRequest(ride_id=ride_id)
    with pytest.raises(RuleViolationError) as exc_info:
        await payment_service.initiate_stk_push(passenger_id=passenger_id, payload=payload)

    assert "already succeeded" in str(exc_info.value)


@pytest.mark.asyncio
async def test_stk_push_bambastack_unavailable(payment_service, mock_deps):
    """BambaStack infrastructure failure raises RuleViolationError."""
    from app.services.bambastack_client import BambaStackException
    p_repo, r_repo, u_repo, bambastack, pubsub = mock_deps
    passenger_id = uuid4()
    ride_id = uuid4()

    r_repo.get_ride.return_value = RideResponse(
        id=ride_id, passenger_id=passenger_id, rider_id=None, status="FARE_ACCEPTED",
        payment_status="PENDING", version=1, created_at=datetime.now(timezone.utc), updated_at=datetime.now(timezone.utc)
    )
    p_repo.get_default_active_payment_account.return_value = {
        "id": str(uuid4()), "provider": "MPESA_TILL", "display_name": "7s Till",
        "till_paybill_or_number": "123456", "is_default": True, "status": "active"
    }
    u_repo.get_user_by_id.return_value = {"id": str(passenger_id), "phone_number": "0712345678", "role": "PASSENGER"}

    conn_mock = AsyncMock()
    conn_mock.fetchrow.return_value = {"fare_amount": 200.0}
    pool_mock = MagicMock()
    pool_mock.acquire.return_value.__aenter__.return_value = conn_mock
    r_repo._get_pool.return_value = pool_mock

    bambastack.send_stk_push.side_effect = BambaStackException("BambaStack STK Push request timed out.")

    payload = STKPushRequest(ride_id=ride_id)
    with pytest.raises(RuleViolationError) as exc_info:
        await payment_service.initiate_stk_push(passenger_id=passenger_id, payload=payload)

    assert "M-PESA payment request failed" in str(exc_info.value)


@pytest.mark.asyncio
async def test_stk_push_duplicate_reference(payment_service, mock_deps):
    """BambaStack HTTP 409 (duplicate reference) propagates as RuleViolationError."""
    from app.services.bambastack_client import BambaStackException
    p_repo, r_repo, u_repo, bambastack, pubsub = mock_deps
    passenger_id = uuid4()
    ride_id = uuid4()

    r_repo.get_ride.return_value = RideResponse(
        id=ride_id, passenger_id=passenger_id, rider_id=None, status="FARE_ACCEPTED",
        payment_status="PENDING", version=1, created_at=datetime.now(timezone.utc), updated_at=datetime.now(timezone.utc)
    )
    p_repo.get_default_active_payment_account.return_value = {
        "id": str(uuid4()), "provider": "MPESA_TILL", "display_name": "7s Till",
        "till_paybill_or_number": "123456", "is_default": True, "status": "active"
    }
    u_repo.get_user_by_id.return_value = {"id": str(passenger_id), "phone_number": "0712345678", "role": "PASSENGER"}

    conn_mock = AsyncMock()
    conn_mock.fetchrow.return_value = {"fare_amount": 200.0}
    pool_mock = MagicMock()
    pool_mock.acquire.return_value.__aenter__.return_value = conn_mock
    r_repo._get_pool.return_value = pool_mock

    bambastack.send_stk_push.side_effect = BambaStackException(f"BambaStack rejected STK Push: duplicate reference '{ride_id}'.")

    payload = STKPushRequest(ride_id=ride_id)
    with pytest.raises(RuleViolationError) as exc_info:
        await payment_service.initiate_stk_push(passenger_id=passenger_id, payload=payload)

    assert "duplicate reference" in str(exc_info.value)


# ===========================================================================
# 2. BAMBASTACK WEBHOOK CALLBACK
# ===========================================================================

@pytest.mark.asyncio
async def test_bambastack_callback_success(payment_service, mock_deps):
    """Successful BambaStack callback AND authoritative status 'paid' creates PAYMENT_SUCCESS event."""
    p_repo, r_repo, u_repo, bambastack, pubsub = mock_deps
    ride_id = uuid4()

    p_repo.get_payment_by_checkout_request_id.return_value = {
        "id": str(uuid4()), "ride_id": str(ride_id), "amount": 350.0, "phone_number_used": "0712345678"
    }
    bambastack.get_payment_status.return_value = {"status": "paid", "amount": 350.0}
    p_repo.insert_payment_event.return_value = {"id": str(uuid4())}
    r_repo.get_ride.return_value = RideResponse(
        id=ride_id, passenger_id=uuid4(), rider_id=None, status="IN_PROGRESS",
        payment_status="SUCCESS", version=3, created_at=datetime.now(timezone.utc), updated_at=datetime.now(timezone.utc)
    )

    callback_payload = BambaStackCallbackPayload(
        checkout_request_id="chk-bamba-001",
        ResultCode=0,
        ResultDesc="The service request is processed successfully.",
        MpesaReceiptNumber="RHE12ABC3D"
    )

    res = await payment_service.handle_bambastack_callback(callback_payload)
    assert res["status"] == "processed"
    p_repo.insert_payment_event.assert_called_once()
    bambastack.get_payment_status.assert_called_once_with(str(ride_id))
    # Verify the event type is PAYMENT_SUCCESS
    call_args = p_repo.insert_payment_event.call_args[0][0]
    assert call_args.payment_event_type == "PAYMENT_SUCCESS"
    assert call_args.mpesa_receipt == "RHE12ABC3D"


@pytest.mark.asyncio
async def test_bambastack_callback_failure(payment_service, mock_deps):
    """Failed BambaStack callback creates PAYMENT_FAILED event based on authoritative provider status."""
    p_repo, r_repo, u_repo, bambastack, pubsub = mock_deps
    ride_id = uuid4()

    p_repo.get_payment_by_checkout_request_id.return_value = {
        "id": str(uuid4()), "ride_id": str(ride_id), "amount": 350.0, "phone_number_used": "0712345678"
    }
    bambastack.get_payment_status.return_value = {"status": "failed"}
    p_repo.insert_payment_event.return_value = {"id": str(uuid4())}
    r_repo.get_ride.return_value = RideResponse(
        id=ride_id, passenger_id=uuid4(), rider_id=None, status="IN_PROGRESS",
        payment_status="FAILED", version=3, created_at=datetime.now(timezone.utc), updated_at=datetime.now(timezone.utc)
    )

    callback_payload = BambaStackCallbackPayload(
        checkout_request_id="chk-bamba-002",
        ResultCode=1032,
        ResultDesc="[STK_CB - ]Request cancelled by user"
    )

    res = await payment_service.handle_bambastack_callback(callback_payload)
    assert res["status"] == "processed"
    call_args = p_repo.insert_payment_event.call_args[0][0]
    assert call_args.payment_event_type == "PAYMENT_FAILED"


@pytest.mark.asyncio
async def test_bambastack_callback_forged_success(payment_service, mock_deps):
    """Forged successful webhook (ResultCode=0) but provider is pending/failed is rejected."""
    p_repo, r_repo, u_repo, bambastack, pubsub = mock_deps
    ride_id = uuid4()

    p_repo.get_payment_by_checkout_request_id.return_value = {
        "id": str(uuid4()), "ride_id": str(ride_id), "amount": 350.0, "phone_number_used": "0712345678"
    }
    bambastack.get_payment_status.return_value = {"status": "pending"}

    callback_payload = BambaStackCallbackPayload(
        checkout_request_id="chk-bamba-forged",
        ResultCode=0,
        ResultDesc="Success",
        MpesaReceiptNumber="FAKE"
    )

    res = await payment_service.handle_bambastack_callback(callback_payload)

    assert res["status"] == "ignored"
    assert res["reason"] == "provider_status_pending"
    p_repo.insert_payment_event.assert_not_called()


@pytest.mark.asyncio
async def test_bambastack_callback_amount_mismatch(payment_service, mock_deps):
    """Successful webhook but authoritative provider amount differs from expected amount."""
    p_repo, r_repo, u_repo, bambastack, pubsub = mock_deps
    ride_id = uuid4()

    p_repo.get_payment_by_checkout_request_id.return_value = {
        "id": str(uuid4()), "ride_id": str(ride_id), "amount": 350.0, "phone_number_used": "0712345678"
    }
    # Provider reports only 1 KES was paid
    bambastack.get_payment_status.return_value = {"status": "paid", "amount": 1.0}

    callback_payload = BambaStackCallbackPayload(
        checkout_request_id="chk-bamba-amount-mismatch",
        ResultCode=0,
        ResultDesc="Success"
    )

    res = await payment_service.handle_bambastack_callback(callback_payload)

    assert res["status"] == "ignored"
    assert res["reason"] == "amount_mismatch"
    p_repo.insert_payment_event.assert_not_called()


@pytest.mark.asyncio
async def test_bambastack_callback_unknown_checkout_id(payment_service, mock_deps):
    """Webhook for unknown checkout_request_id raises ResourceNotFoundError — no phantom payment created."""
    p_repo, r_repo, u_repo, bambastack, pubsub = mock_deps

    p_repo.get_payment_by_checkout_request_id.return_value = None

    callback_payload = BambaStackCallbackPayload(
        checkout_request_id="chk-unknown-999",
        ResultCode=0,
        ResultDesc="Success",
        MpesaReceiptNumber="ABC123"
    )

    with pytest.raises(ResourceNotFoundError):
        await payment_service.handle_bambastack_callback(callback_payload)

    # No payment event must be created for unknown callbacks
    p_repo.insert_payment_event.assert_not_called()


@pytest.mark.asyncio
async def test_bambastack_callback_duplicate_idempotent(payment_service, mock_deps):
    """Duplicate callback for already-succeeded payment is safely ignored (BR-010)."""
    import asyncpg
    p_repo, r_repo, u_repo, bambastack, pubsub = mock_deps
    ride_id = uuid4()

    p_repo.get_payment_by_checkout_request_id.return_value = {
        "id": str(uuid4()), "ride_id": str(ride_id), "amount": 350.0, "phone_number_used": "0712345678"
    }
    bambastack.get_payment_status.return_value = {"status": "paid", "amount": 350.0}

    # DB trigger rejects duplicate SUCCESS
    p_repo.insert_payment_event.side_effect = asyncpg.exceptions.RaiseError("Cannot create PAYMENT_SUCCESS — payment already succeeded (BR-010).")

    callback_payload = BambaStackCallbackPayload(
        checkout_request_id="chk-bamba-001",
        ResultCode=0,
        ResultDesc="Success",
        MpesaReceiptNumber="RHE12ABC3D"
    )

    res = await payment_service.handle_bambastack_callback(callback_payload)
    assert res["status"] == "ignored"
    assert "already succeeded" in res["reason"]


# ===========================================================================
# 3. WEBHOOK HTTP ROUTE TESTS
# ===========================================================================

import starlette.testclient
from main import app
from app.api.dependencies import get_current_user, get_payment_service
from app.schemas.auth import TokenPayload


def test_bambastack_webhook_valid_payload():
    """Webhook route accepts valid BambaStack callback payload."""
    client = starlette.testclient.TestClient(app)
    mock_service = AsyncMock()
    mock_service.handle_bambastack_callback.return_value = {"status": "processed", "event_id": str(uuid4())}
    app.dependency_overrides[get_payment_service] = lambda: mock_service
    try:
        response = client.post(
            "/api/v1/payments/bambastack/webhook",
            json={
                "checkout_request_id": "chk-001",
                "ResultCode": 0,
                "ResultDesc": "Success",
                "MpesaReceiptNumber": "RHE12ABC3D"
            }
        )
        assert response.status_code == 200
        assert response.json()["status"] == "processed"
    finally:
        app.dependency_overrides.clear()


def test_bambastack_webhook_malformed_payload():
    """Webhook route rejects malformed payload (missing required fields)."""
    client = starlette.testclient.TestClient(app)
    response = client.post(
        "/api/v1/payments/bambastack/webhook",
        json={"ResultCode": 0}  # Missing checkout_request_id and ResultDesc
    )
    assert response.status_code == 422


def test_bambastack_webhook_empty_body():
    """Webhook route rejects empty body."""
    client = starlette.testclient.TestClient(app)
    response = client.post(
        "/api/v1/payments/bambastack/webhook",
        json={}
    )
    assert response.status_code == 422


def test_bambastack_webhook_not_found_payment():
    """Webhook returns 404 when checkout_request_id doesn't match existing payment."""
    client = starlette.testclient.TestClient(app)
    mock_service = AsyncMock()
    mock_service.handle_bambastack_callback.side_effect = ResourceNotFoundError("Payment attempt not found")
    app.dependency_overrides[get_payment_service] = lambda: mock_service
    try:
        response = client.post(
            "/api/v1/payments/bambastack/webhook",
            json={
                "checkout_request_id": "chk-unknown",
                "ResultCode": 0,
                "ResultDesc": "Success"
            }
        )
        assert response.status_code == 404
    finally:
        app.dependency_overrides.clear()


# ===========================================================================
# 4. PROVIDER-NEUTRAL PAYMENT TESTS (Cash, Dispute, Refund, Status)
# ===========================================================================

@pytest.mark.asyncio
async def test_confirm_cash_payment_rider(payment_service, mock_deps):
    """Rider can confirm cash payment (BR-011)."""
    p_repo, r_repo, u_repo, bambastack, pubsub = mock_deps
    rider_id = uuid4()
    ride_id = uuid4()

    r_repo.get_ride.return_value = RideResponse(
        id=ride_id, passenger_id=uuid4(), rider_id=rider_id, status="ARRIVED",
        payment_status="PENDING", version=2, created_at=datetime.now(timezone.utc), updated_at=datetime.now(timezone.utc)
    )

    conn_mock = AsyncMock()
    conn_mock.fetchrow.return_value = {"fare_amount": 250.0}
    pool_mock = MagicMock()
    pool_mock.acquire.return_value.__aenter__.return_value = conn_mock
    r_repo._get_pool.return_value = pool_mock

    p_repo.insert_payment_event.return_value = {"id": str(uuid4())}

    res = await payment_service.confirm_cash_payment(actor_id=rider_id, actor_role="RIDER", ride_id=ride_id)
    assert res["status"] == "success"
    p_repo.insert_payment_event.assert_called_once()


@pytest.mark.asyncio
async def test_manual_refund_requires_success(payment_service, mock_deps):
    """Refund rejected when payment_status != SUCCESS."""
    p_repo, r_repo, u_repo, bambastack, pubsub = mock_deps
    owner_id = uuid4()
    ride_id = uuid4()

    r_repo.get_ride.return_value = RideResponse(
        id=ride_id, passenger_id=uuid4(), rider_id=None, status="COMPLETED",
        payment_status="PENDING", version=2, created_at=datetime.now(timezone.utc), updated_at=datetime.now(timezone.utc)
    )

    with pytest.raises(RuleViolationError) as exc_info:
        await payment_service.record_manual_refund(owner_id=owner_id, owner_role="OWNER", ride_id=ride_id, reason="Customer overcharged")

    assert "payment_status = SUCCESS" in str(exc_info.value)
    p_repo.insert_payment_event.assert_not_called()


@pytest.mark.asyncio
async def test_record_cash_dispute_success(payment_service, mock_deps):
    """Cash dispute records PAYMENT_DISPUTED event."""
    p_repo, r_repo, u_repo, bambastack, pubsub = mock_deps
    passenger_id = uuid4()
    ride_id = uuid4()

    r_repo.get_ride.return_value = RideResponse(
        id=ride_id, passenger_id=passenger_id, rider_id=uuid4(), status="COMPLETED",
        payment_status="PENDING", version=3, created_at=datetime.now(timezone.utc), updated_at=datetime.now(timezone.utc)
    )
    p_repo.insert_payment_event.return_value = {"id": str(uuid4())}

    res = await payment_service.record_cash_dispute(
        actor_id=passenger_id, actor_role="PASSENGER", ride_id=ride_id, reason="Driver demanded extra cash"
    )
    assert res["status"] == "disputed"
    p_repo.insert_payment_event.assert_called_once()


def test_missing_role_claim_rejected():
    """Missing role claim in JWT returns 401."""
    client = starlette.testclient.TestClient(app)
    app.dependency_overrides[get_current_user] = lambda: TokenPayload(sub=str(uuid4()), role=None)
    try:
        response = client.post(f"/api/v1/payments/{uuid4()}/confirm-cash")
        assert response.status_code == 401
        assert "sub and role claims are required" in response.json()["detail"]
    finally:
        app.dependency_overrides.clear()


# ===========================================================================
# 5. PAYMENT STATUS POLLING
# ===========================================================================

@pytest.mark.asyncio
async def test_get_payment_status_pending_non_terminal(payment_service, mock_deps):
    """PENDING payment returns is_terminal=False — Flutter must keep polling/listening."""
    p_repo, r_repo, u_repo, bambastack, pubsub = mock_deps
    passenger_id = uuid4()
    ride_id = uuid4()

    r_repo.get_ride.return_value = RideResponse(
        id=ride_id, passenger_id=passenger_id, rider_id=None, status="IN_PROGRESS",
        payment_status="PENDING", version=2,
        created_at=datetime.now(timezone.utc), updated_at=datetime.now(timezone.utc)
    )
    p_repo.get_latest_payment_attempt.return_value = {
        "id": str(uuid4()), "ride_id": str(ride_id), "amount": 350.0,
        "metadata": {"payment_method": "MPESA", "CheckoutRequestID": "chk-999"}
    }

    result = await payment_service.get_payment_status(passenger_id=passenger_id, ride_id=ride_id)

    assert result.payment_status == "PENDING"
    assert result.payment_method == "MPESA"
    assert result.is_terminal is False
    assert result.ride_id == ride_id


@pytest.mark.asyncio
async def test_get_payment_status_success_is_terminal(payment_service, mock_deps):
    """SUCCESS payment returns is_terminal=True — Flutter must stop polling."""
    p_repo, r_repo, u_repo, bambastack, pubsub = mock_deps
    passenger_id = uuid4()
    ride_id = uuid4()

    r_repo.get_ride.return_value = RideResponse(
        id=ride_id, passenger_id=passenger_id, rider_id=None, status="COMPLETED",
        payment_status="SUCCESS", version=3,
        created_at=datetime.now(timezone.utc), updated_at=datetime.now(timezone.utc)
    )
    p_repo.get_latest_payment_attempt.return_value = {
        "id": str(uuid4()), "ride_id": str(ride_id), "amount": 350.0,
        "metadata": {"payment_method": "MPESA", "CheckoutRequestID": "chk-999"}
    }

    result = await payment_service.get_payment_status(passenger_id=passenger_id, ride_id=ride_id)

    assert result.payment_status == "SUCCESS"
    assert result.is_terminal is True


@pytest.mark.asyncio
async def test_get_payment_status_unauthorized_different_passenger(payment_service, mock_deps):
    """A different passenger cannot poll another ride's payment status."""
    from app.domain.exceptions import UnauthorizedError
    p_repo, r_repo, u_repo, bambastack, pubsub = mock_deps
    real_passenger_id = uuid4()
    attacker_id = uuid4()
    ride_id = uuid4()

    r_repo.get_ride.return_value = RideResponse(
        id=ride_id, passenger_id=real_passenger_id, rider_id=None, status="IN_PROGRESS",
        payment_status="PENDING", version=1,
        created_at=datetime.now(timezone.utc), updated_at=datetime.now(timezone.utc)
    )

    with pytest.raises(UnauthorizedError):
        await payment_service.get_payment_status(passenger_id=attacker_id, ride_id=ride_id)

    p_repo.get_latest_payment_attempt.assert_not_called()


# ===========================================================================
# 6. RECONCILIATION (BambaStack Status Polling)
# ===========================================================================

@pytest.mark.asyncio
async def test_reconcile_pending_payments_paid(payment_service, mock_deps):
    """Reconciliation: BambaStack status 'paid' creates PAYMENT_SUCCESS event."""
    p_repo, r_repo, u_repo, bambastack, pubsub = mock_deps
    ride_id = uuid4()

    p_repo.get_pending_stk_payments.return_value = [
        {
            "ride_id": str(ride_id),
            "checkout_request_id": "chk-reconcile-99",
            "amount": 400.0,
            "phone_number_used": "0712345678",
            "attempt_time": datetime.now(timezone.utc)
        }
    ]
    bambastack.get_payment_status.return_value = {"status": "paid", "reference": str(ride_id)}
    p_repo.insert_payment_event.return_value = {"id": str(uuid4())}
    r_repo.get_ride.return_value = RideResponse(
        id=ride_id, passenger_id=uuid4(), rider_id=None, status="IN_PROGRESS",
        payment_status="SUCCESS", version=4, created_at=datetime.now(timezone.utc), updated_at=datetime.now(timezone.utc)
    )

    res = await payment_service.reconcile_pending_payments(timeout_seconds=90)
    assert res["reconciled_count"] == 1
    assert res["results"][0]["status"] == "reconciled"
    assert res["results"][0]["event_type"] == "PAYMENT_SUCCESS"
    bambastack.get_payment_status.assert_called_once_with(str(ride_id))


@pytest.mark.asyncio
async def test_reconcile_pending_payments_failed(payment_service, mock_deps):
    """Reconciliation: BambaStack status 'failed' creates PAYMENT_FAILED event."""
    p_repo, r_repo, u_repo, bambastack, pubsub = mock_deps
    ride_id = uuid4()

    p_repo.get_pending_stk_payments.return_value = [
        {
            "ride_id": str(ride_id),
            "checkout_request_id": "chk-reconcile-100",
            "amount": 200.0,
            "phone_number_used": "0712345678",
            "attempt_time": datetime.now(timezone.utc)
        }
    ]
    bambastack.get_payment_status.return_value = {"status": "failed"}
    p_repo.insert_payment_event.return_value = {"id": str(uuid4())}
    r_repo.get_ride.return_value = RideResponse(
        id=ride_id, passenger_id=uuid4(), rider_id=None, status="IN_PROGRESS",
        payment_status="FAILED", version=4, created_at=datetime.now(timezone.utc), updated_at=datetime.now(timezone.utc)
    )

    res = await payment_service.reconcile_pending_payments(timeout_seconds=90)
    assert res["reconciled_count"] == 1
    assert res["results"][0]["event_type"] == "PAYMENT_FAILED"


@pytest.mark.asyncio
async def test_reconcile_pending_payments_still_pending(payment_service, mock_deps):
    """Reconciliation: BambaStack status 'pending' skips — no event created."""
    p_repo, r_repo, u_repo, bambastack, pubsub = mock_deps
    ride_id = uuid4()

    p_repo.get_pending_stk_payments.return_value = [
        {
            "ride_id": str(ride_id),
            "checkout_request_id": "chk-reconcile-101",
            "amount": 200.0,
            "phone_number_used": "0712345678",
            "attempt_time": datetime.now(timezone.utc)
        }
    ]
    bambastack.get_payment_status.return_value = {"status": "pending"}

    res = await payment_service.reconcile_pending_payments(timeout_seconds=90)
    assert res["reconciled_count"] == 1
    assert res["results"][0]["status"] == "still_pending"
    p_repo.insert_payment_event.assert_not_called()


@pytest.mark.asyncio
async def test_reconcile_pending_payments_cancelled(payment_service, mock_deps):
    """Reconciliation: BambaStack status 'cancelled' creates PAYMENT_FAILED event."""
    p_repo, r_repo, u_repo, bambastack, pubsub = mock_deps
    ride_id = uuid4()

    p_repo.get_pending_stk_payments.return_value = [
        {
            "ride_id": str(ride_id),
            "checkout_request_id": "chk-reconcile-102",
            "amount": 300.0,
            "phone_number_used": "0712345678",
            "attempt_time": datetime.now(timezone.utc)
        }
    ]
    bambastack.get_payment_status.return_value = {"status": "cancelled"}
    p_repo.insert_payment_event.return_value = {"id": str(uuid4())}
    r_repo.get_ride.return_value = RideResponse(
        id=ride_id, passenger_id=uuid4(), rider_id=None, status="IN_PROGRESS",
        payment_status="FAILED", version=4, created_at=datetime.now(timezone.utc), updated_at=datetime.now(timezone.utc)
    )

    res = await payment_service.reconcile_pending_payments(timeout_seconds=90)
    assert res["reconciled_count"] == 1
    assert res["results"][0]["event_type"] == "PAYMENT_FAILED"


# ===========================================================================
# 7. PAYMENT CANNOT BECOME SUCCESS WITHOUT PROVIDER CONFIRMATION
# ===========================================================================

@pytest.mark.asyncio
async def test_stk_push_does_not_create_success_event(payment_service, mock_deps):
    """STK Push initiation creates PAYMENT_ATTEMPT (PENDING), never PAYMENT_SUCCESS."""
    p_repo, r_repo, u_repo, bambastack, pubsub = mock_deps
    passenger_id = uuid4()
    ride_id = uuid4()

    r_repo.get_ride.return_value = RideResponse(
        id=ride_id, passenger_id=passenger_id, rider_id=None, status="FARE_ACCEPTED",
        payment_status="PENDING", version=1, created_at=datetime.now(timezone.utc), updated_at=datetime.now(timezone.utc)
    )
    p_repo.get_default_active_payment_account.return_value = {
        "id": str(uuid4()), "provider": "MPESA_TILL", "display_name": "7s Till",
        "till_paybill_or_number": "123456", "is_default": True, "status": "active"
    }
    u_repo.get_user_by_id.return_value = {"id": str(passenger_id), "phone_number": "0712345678", "role": "PASSENGER"}

    conn_mock = AsyncMock()
    conn_mock.fetchrow.return_value = {"fare_amount": 200.0}
    pool_mock = MagicMock()
    pool_mock.acquire.return_value.__aenter__.return_value = conn_mock
    r_repo._get_pool.return_value = pool_mock

    bambastack.send_stk_push.return_value = {
        "transaction_id": "trx-002",
        "checkout_request_id": "chk-002"
    }

    payload = STKPushRequest(ride_id=ride_id)
    await payment_service.initiate_stk_push(passenger_id=passenger_id, payload=payload)

    # Verify only PAYMENT_ATTEMPT was created, not PAYMENT_SUCCESS
    call_args = p_repo.insert_payment_event.call_args[0][0]
    assert call_args.payment_event_type == "PAYMENT_ATTEMPT"
    assert call_args.payment_event_type != "PAYMENT_SUCCESS"
