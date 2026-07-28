import pytest
from unittest.mock import AsyncMock, patch, MagicMock
from uuid import uuid4
from datetime import datetime, timezone

from app.schemas.payments import STKPushRequest, DarajaCallbackPayload, DarajaCallbackBody, STKCallback, STKCallbackMetadata, CallbackMetadataItem
from app.services.payment_service import PaymentService
from app.schemas.rides import RideResponse
from app.domain.exceptions import RuleViolationError, UnauthorizedError, ResourceNotFoundError

@pytest.fixture
def mock_deps():
    payment_repo = AsyncMock()
    ride_repo = AsyncMock()
    user_repo = AsyncMock()
    daraja_client = AsyncMock()
    pubsub_service = AsyncMock()
    return payment_repo, ride_repo, user_repo, daraja_client, pubsub_service

@pytest.fixture
def payment_service(mock_deps):
    p_repo, r_repo, u_repo, daraja, pubsub = mock_deps
    return PaymentService(
        payment_repo=p_repo,
        ride_repo=r_repo,
        user_repo=u_repo,
        daraja_client=daraja,
        pubsub_service=pubsub
    )

@pytest.mark.asyncio
async def test_stk_push_no_payment_account_gating(payment_service, mock_deps):
    p_repo, r_repo, u_repo, daraja, pubsub = mock_deps
    passenger_id = uuid4()
    ride_id = uuid4()

    r_repo.get_ride.return_value = RideResponse(
        id=ride_id, passenger_id=passenger_id, rider_id=None, status="FARE_SENT",
        payment_status="PENDING", version=1, created_at=datetime.now(timezone.utc), updated_at=datetime.now(timezone.utc)
    )
    # BR-010: No default active payment account configured
    p_repo.get_default_active_payment_account.return_value = None

    payload = STKPushRequest(ride_id=ride_id)
    with pytest.raises(RuleViolationError) as exc_info:
        await payment_service.initiate_stk_push(passenger_id=passenger_id, payload=payload)

    assert "M-PESA payments are currently unavailable" in str(exc_info.value)
    daraja.send_stk_push.assert_not_called()

@pytest.mark.asyncio
async def test_stk_push_already_paid(payment_service, mock_deps):
    p_repo, r_repo, u_repo, daraja, pubsub = mock_deps
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
async def test_stk_push_success(payment_service, mock_deps):
    p_repo, r_repo, u_repo, daraja, pubsub = mock_deps
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

    # Mock DB pool acquire for fare_amount check
    conn_mock = AsyncMock()
    conn_mock.fetchrow.return_value = {"fare_amount": 350.0}
    pool_mock = MagicMock()
    pool_mock.acquire.return_value.__aenter__.return_value = conn_mock
    r_repo._get_pool.return_value = pool_mock

    daraja.send_stk_push.return_value = MagicMock(
        MerchantRequestID="req-123", CheckoutRequestID="chk-456",
        ResponseCode="0", ResponseDescription="Success", CustomerMessage="Prompt sent"
    )

    payload = STKPushRequest(ride_id=ride_id)
    res = await payment_service.initiate_stk_push(passenger_id=passenger_id, payload=payload)

    assert res.CheckoutRequestID == "chk-456"
    daraja.send_stk_push.assert_called_once()
    p_repo.insert_payment_event.assert_called_once()

@pytest.mark.asyncio
async def test_daraja_callback_success(payment_service, mock_deps):
    p_repo, r_repo, u_repo, daraja, pubsub = mock_deps
    ride_id = uuid4()

    p_repo.get_payment_by_checkout_request_id.return_value = {
        "id": str(uuid4()), "ride_id": str(ride_id), "amount": 350.0, "phone_number_used": "254712345678"
    }
    p_repo.insert_payment_event.return_value = {"id": str(uuid4())}
    r_repo.get_ride.return_value = RideResponse(
        id=ride_id, passenger_id=uuid4(), rider_id=None, status="IN_PROGRESS",
        payment_status="SUCCESS", version=3, created_at=datetime.now(timezone.utc), updated_at=datetime.now(timezone.utc)
    )

    callback_payload = DarajaCallbackPayload(
        Body=DarajaCallbackBody(
            stkCallback=STKCallback(
                MerchantRequestID="req-123",
                CheckoutRequestID="chk-456",
                ResultCode=0,
                ResultDesc="The service request has been processed successfully.",
                CallbackMetadata=STKCallbackMetadata(
                    Item=[
                        CallbackMetadataItem(Name="MpesaReceiptNumber", Value="QWE123RTY"),
                        CallbackMetadataItem(Name="Amount", Value=350.0)
                    ]
                )
            )
        )
    )

    res = await payment_service.handle_daraja_callback(callback_payload)
    assert res["status"] == "processed"
    p_repo.insert_payment_event.assert_called_once()

@pytest.mark.asyncio
async def test_confirm_cash_payment_rider(payment_service, mock_deps):
    p_repo, r_repo, u_repo, daraja, pubsub = mock_deps
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
    p_repo, r_repo, u_repo, daraja, pubsub = mock_deps
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
    p_repo, r_repo, u_repo, daraja, pubsub = mock_deps
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

@pytest.mark.asyncio
async def test_daraja_callback_db_trigger_rejection_handled(payment_service, mock_deps):
    import asyncpg
    p_repo, r_repo, u_repo, daraja, pubsub = mock_deps
    ride_id = uuid4()

    p_repo.get_payment_by_checkout_request_id.return_value = {
        "id": str(uuid4()), "ride_id": str(ride_id), "amount": 350.0, "phone_number_used": "254712345678"
    }
    # Simulate DB trigger rejecting duplicate PAYMENT_SUCCESS (BR-010 / BR-035)
    p_repo.insert_payment_event.side_effect = asyncpg.exceptions.RaiseError("Cannot create PAYMENT_SUCCESS — payment already succeeded (BR-010).")

    callback_payload = DarajaCallbackPayload(
        Body=DarajaCallbackBody(
            stkCallback=STKCallback(
                MerchantRequestID="req-123",
                CheckoutRequestID="chk-456",
                ResultCode=0,
                ResultDesc="Success",
                CallbackMetadata=STKCallbackMetadata(
                    Item=[CallbackMetadataItem(Name="MpesaReceiptNumber", Value="QWE123RTY")]
                )
            )
        )
    )

    res = await payment_service.handle_daraja_callback(callback_payload)
    assert res["status"] == "ignored"
    assert "already succeeded" in res["reason"]

import starlette.testclient
from main import app
from app.api.dependencies import get_current_user, get_payment_service
from app.schemas.auth import TokenPayload

def test_missing_role_claim_rejected():
    client = starlette.testclient.TestClient(app)
    # Mock authentication returning TokenPayload without role
    app.dependency_overrides[get_current_user] = lambda: TokenPayload(sub=str(uuid4()), role=None)
    try:
        response = client.post(f"/api/v1/payments/{uuid4()}/confirm-cash")
        assert response.status_code == 401
        assert "sub and role claims are required" in response.json()["detail"]
    finally:
        app.dependency_overrides.clear()

def test_daraja_callback_ip_whitelisting_rejection():
    client = starlette.testclient.TestClient(app)
    # Test unallowed IP header
    response = client.post(
        "/api/v1/payments/callback",
        json={
            "Body": {
                "stkCallback": {
                    "MerchantRequestID": "req-123",
                    "CheckoutRequestID": "chk-456",
                    "ResultCode": 0,
                    "ResultDesc": "Success"
                }
            }
        },
        headers={"X-Forwarded-For": "203.0.113.199"}
    )
    assert response.status_code == 403
    assert "not in allowed Safaricom IP ranges" in response.json()["detail"]

def test_daraja_callback_allowed_ip_accepted():
    client = starlette.testclient.TestClient(app)
    mock_service = AsyncMock()
    mock_service.handle_daraja_callback.return_value = {"status": "processed"}
    app.dependency_overrides[get_payment_service] = lambda: mock_service
    try:
        response = client.post(
            "/api/v1/payments/callback",
            json={
                "Body": {
                    "stkCallback": {
                        "MerchantRequestID": "req-123",
                        "CheckoutRequestID": "chk-456",
                        "ResultCode": 1,
                        "ResultDesc": "Cancelled"
                    }
                }
            },
            headers={"X-Forwarded-For": "196.201.214.200"}
        )
        assert response.status_code == 200
        assert response.json()["status"] == "processed"
    finally:
        app.dependency_overrides.clear()

@pytest.mark.asyncio
async def test_reconcile_pending_payments_execution(payment_service, mock_deps):
    p_repo, r_repo, u_repo, daraja, pubsub = mock_deps
    ride_id = uuid4()
    checkout_id = "chk-reconcile-99"

    p_repo.get_pending_stk_payments.return_value = [
        {
            "ride_id": str(ride_id),
            "checkout_request_id": checkout_id,
            "amount": 400.0,
            "phone_number_used": "254712345678",
            "attempt_time": datetime.now(timezone.utc)
        }
    ]
    daraja.query_stk_status.return_value = {"ResultCode": "0", "ResultDesc": "The service request has been processed successfully."}
    p_repo.insert_payment_event.return_value = {"id": str(uuid4())}
    r_repo.get_ride.return_value = RideResponse(
        id=ride_id, passenger_id=uuid4(), rider_id=None, status="IN_PROGRESS",
        payment_status="SUCCESS", version=4, created_at=datetime.now(timezone.utc), updated_at=datetime.now(timezone.utc)
    )

    res = await payment_service.reconcile_pending_payments(timeout_seconds=90)
    assert res["reconciled_count"] == 1
    assert res["results"][0]["status"] == "reconciled"
    assert res["results"][0]["event_type"] == "PAYMENT_SUCCESS"
    daraja.query_stk_status.assert_called_once_with(checkout_id)
    p_repo.insert_payment_event.assert_called_once()

def test_daraja_callback_webhook_secret_token_validation():
    from app.core.config import settings
    from pydantic import SecretStr
    client = starlette.testclient.TestClient(app)

    # Enable secret token check
    original_secret = settings.DARAJA_WEBHOOK_SECRET
    settings.DARAJA_WEBHOOK_SECRET = SecretStr("my-super-secret-token-123")
    try:
        # Invalid token -> 403
        res_invalid = client.post(
            "/api/v1/payments/callback?token=wrong-token",
            json={"Body": {"stkCallback": {"MerchantRequestID": "req", "CheckoutRequestID": "chk", "ResultCode": 0, "ResultDesc": "Success"}}},
            headers={"X-Forwarded-For": "196.201.214.200"}
        )
        assert res_invalid.status_code == 403
        assert "Invalid or missing webhook query secret token" in res_invalid.json()["detail"]

        # Valid token -> 200/proceeds
        mock_service = AsyncMock()
        mock_service.handle_daraja_callback.return_value = {"status": "processed"}
        app.dependency_overrides[get_payment_service] = lambda: mock_service

        res_valid = client.post(
            "/api/v1/payments/callback?token=my-super-secret-token-123",
            json={"Body": {"stkCallback": {"MerchantRequestID": "req", "CheckoutRequestID": "chk", "ResultCode": 0, "ResultDesc": "Success"}}},
            headers={"X-Forwarded-For": "196.201.214.200"}
        )
        assert res_valid.status_code == 200
        assert res_valid.json()["status"] == "processed"
    finally:
        settings.DARAJA_WEBHOOK_SECRET = original_secret
        app.dependency_overrides.clear()

@pytest.mark.asyncio
async def test_reconcile_pending_payments_idempotent_second_run(payment_service, mock_deps):
    p_repo, r_repo, u_repo, daraja, pubsub = mock_deps
    ride_id = uuid4()
    checkout_id = "chk-reconcile-100"

    # First run: finds PENDING payment attempt and reconciles to SUCCESS
    p_repo.get_pending_stk_payments.return_value = [
        {
            "ride_id": str(ride_id),
            "checkout_request_id": checkout_id,
            "amount": 400.0,
            "phone_number_used": "254712345678",
            "attempt_time": datetime.now(timezone.utc)
        }
    ]
    daraja.query_stk_status.return_value = {"ResultCode": "0", "ResultDesc": "Success"}
    p_repo.insert_payment_event.return_value = {"id": str(uuid4())}
    r_repo.get_ride.return_value = RideResponse(
        id=ride_id, passenger_id=uuid4(), rider_id=None, status="IN_PROGRESS",
        payment_status="SUCCESS", version=4, created_at=datetime.now(timezone.utc), updated_at=datetime.now(timezone.utc)
    )

    res1 = await payment_service.reconcile_pending_payments(timeout_seconds=90)
    assert res1["reconciled_count"] == 1

    # Second run: DB query get_pending_stk_payments filters out payment_status='SUCCESS', returning empty list
    p_repo.get_pending_stk_payments.return_value = []

    res2 = await payment_service.reconcile_pending_payments(timeout_seconds=90)
    assert res2["reconciled_count"] == 0
    assert res2["results"] == []


# ---------------------------------------------------------------------------
# GET /payments/{ride_id}/status — fallback poll endpoint (Gate 1, 3B)
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_get_payment_status_pending_non_terminal(payment_service, mock_deps):
    """PENDING payment returns is_terminal=False — Flutter must keep polling/listening."""
    p_repo, r_repo, u_repo, daraja, pubsub = mock_deps
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
    p_repo, r_repo, u_repo, daraja, pubsub = mock_deps
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
    p_repo, r_repo, u_repo, daraja, pubsub = mock_deps
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
