import asyncpg
import logging
from typing import Dict, Any, Optional
from uuid import UUID

from app.repositories.payment_repository import PaymentRepository
from app.repositories.ride_repository import RideRepository
from app.repositories.user_repository import UserRepository
from app.services.bambastack_client import BambaStackClient, BambaStackException
from app.schemas.payments import STKPushRequest, BambaStackSTKResponse, BambaStackCallbackPayload, PaymentEventCreate, PaymentStatusResponse, _TERMINAL_PAYMENT_STATUSES
from app.domain.exceptions import RuleViolationError, UnauthorizedError, ResourceNotFoundError
from app.domain.pubsub import PubSubInterface

logger = logging.getLogger("7s.payment_service")

class PaymentService:
    def __init__(
        self,
        payment_repo: PaymentRepository,
        ride_repo: RideRepository,
        user_repo: UserRepository,
        bambastack_client: BambaStackClient,
        pubsub_service: PubSubInterface
    ):
        self.payment_repo = payment_repo
        self.ride_repo = ride_repo
        self.user_repo = user_repo
        self.bambastack = bambastack_client
        self.pubsub = pubsub_service

    async def initiate_stk_push(self, passenger_id: UUID, payload: STKPushRequest) -> BambaStackSTKResponse:
        """
        Initiates an M-PESA STK Push for a ride via BambaStack.
        Enforces BR-010 (payment account gating), BR-035 (no attempt after success), and Document 4 Concurrency Control & Idempotency section (idempotency by ride_id).
        """
        ride = await self.ride_repo.get_ride(payload.ride_id)
        if ride.passenger_id != passenger_id:
            raise UnauthorizedError(f"Passenger {passenger_id} is not authorized for ride {payload.ride_id}")

        if ride.payment_status == "SUCCESS":
            raise RuleViolationError("Payment for this ride has already succeeded (BR-035).")

        # Payment account gating (BR-010)
        account = await self.payment_repo.get_default_active_payment_account()
        if not account:
            raise RuleViolationError("M-PESA payments are currently unavailable. No active default payment account configured (BR-010).")

        # Phone number resolution: user input override or registered passenger phone
        phone_number = payload.phone_number
        if not phone_number:
            passenger = await self.user_repo.get_user_by_id(passenger_id)
            if not passenger or not passenger.get("phone_number"):
                raise RuleViolationError("No registered phone number found for passenger.")
            phone_number = passenger["phone_number"]

        # Ensure Kenyan format (2547... or 07... — BambaStack accepts both)
        formatted_phone = phone_number.replace("+", "").strip()
        if formatted_phone.startswith("254"):
            # Convert to local 07xx format for BambaStack
            formatted_phone = "0" + formatted_phone[3:]
        if not (formatted_phone.startswith("07") or formatted_phone.startswith("01")):
            raise RuleViolationError("Phone number must be a valid Kenyan mobile number.")

        # Fetch fare amount (read from ride table, never trusted from client)
        conn_pool = await self.ride_repo._get_pool()
        async with conn_pool.acquire() as conn:
            row = await conn.fetchrow("SELECT fare_amount FROM rides WHERE id = $1", str(payload.ride_id))
            fare_amount = float(row["fare_amount"]) if row and row["fare_amount"] is not None else None

        if not fare_amount or fare_amount <= 0:
            raise RuleViolationError("Ride fare amount has not been set or is invalid.")

        # Use ride_id as the unique BambaStack payment reference
        reference = str(payload.ride_id)

        try:
            # Trigger STK Push via BambaStack gateway
            bambastack_response = await self.bambastack.send_stk_push(
                phone=formatted_phone,
                amount=int(fare_amount),
                reference=reference,
                description=f"Payment for 7s Ride {reference[:8]}"
            )
        except BambaStackException as e:
            logger.error(f"BambaStack STK push failed for ride {payload.ride_id}: {e}")
            raise RuleViolationError(f"M-PESA payment request failed: {str(e)}")

        transaction_id = bambastack_response.get("transaction_id", "")
        checkout_request_id = bambastack_response.get("checkout_request_id", "")

        stk_response = BambaStackSTKResponse(
            transaction_id=transaction_id,
            checkout_request_id=checkout_request_id,
        )

        # Log PAYMENT_ATTEMPT event in immutable log
        # Trigger updates rides.payment_status to PENDING automatically via DB trigger (BR-022)
        event_dto = PaymentEventCreate(
            ride_id=payload.ride_id,
            payment_event_type="PAYMENT_ATTEMPT",
            phone_number_used=formatted_phone,
            amount=fare_amount,
            metadata={
                "transaction_id": transaction_id,
                "CheckoutRequestID": checkout_request_id,
                "provider": "BAMBASTACK",
                "reference": reference,
            }
        )

        try:
            await self.payment_repo.insert_payment_event(event_dto)
        except asyncpg.exceptions.RaiseError as e:
            raise RuleViolationError(f"Database rejected payment attempt: {str(e)}")

        updated_ride = await self.ride_repo.get_ride(payload.ride_id)
        await self.pubsub.publish(f"ride_{payload.ride_id}", updated_ride.model_dump(mode='json'))

        return stk_response

    async def handle_bambastack_callback(self, payload: BambaStackCallbackPayload) -> Dict[str, Any]:
        """
        Webhook callback handler for BambaStack payment resolution.
        Strictly logs PAYMENT_SUCCESS or PAYMENT_FAILED event.
        Database trigger updates rides.payment_status (BR-022, BR-010, BR-035).

        Idempotency: If the ride already has payment_status=SUCCESS, the DB trigger
        rejects duplicate SUCCESS events (BR-010), and we return 'ignored'.
        """
        from app.core.rate_limit import webhook_payment_cooldown

        checkout_request_id = payload.checkout_request_id
        result_code = payload.ResultCode
        result_desc = payload.ResultDesc

        # Concurrency/Cooldown Check
        if not await webhook_payment_cooldown.check_allow(checkout_request_id):
            logger.warning(f"Payment webhook cooldown active for {checkout_request_id}")
            return {"status": "ignored", "reason": "cooldown"}

        # Correlate callback to an existing 7s payment attempt
        attempt_event = await self.payment_repo.get_payment_by_checkout_request_id(checkout_request_id)
        if not attempt_event:
            logger.warning(f"Received BambaStack callback for unknown checkout_request_id: {checkout_request_id}")
            raise ResourceNotFoundError(f"Payment attempt for checkout_request_id {checkout_request_id} not found")

        ride_id = UUID(str(attempt_event["ride_id"]))
        reference = str(ride_id)
        raw_callback_dict = payload.model_dump(mode='json')

        # Terminal Deduplication Check (Layer 2)
        ride = await self.ride_repo.get_ride(ride_id)
        if ride.payment_status in _TERMINAL_PAYMENT_STATUSES:
            logger.info(f"Payment webhook ignored - payment {ride_id} is already in terminal state {ride.payment_status}")
            return {"status": "ignored", "reason": "payment_already_terminal"}

        # AUTHORITATIVE VERIFICATION
        # Do not trust the webhook ResultCode. Fetch authoritative status from BambaStack.
        try:
            bambastack_status = await self.bambastack.get_payment_status(reference)
            provider_status = str(bambastack_status.get("status", "")).lower()
        except Exception as e:
            logger.error(f"Failed to verify authoritative BambaStack status for reference {reference}: {e}")
            return {"status": "ignored", "reason": "provider_verification_failed"}

        event_dto = None

        if provider_status == "paid":
            # Payment Successful according to authoritative provider
            provider_amount = bambastack_status.get("amount")
            expected_amount = attempt_event.get("amount")

            if provider_amount is not None and expected_amount is not None:
                if float(provider_amount) != float(expected_amount):
                    logger.warning(f"Payment amount mismatch: checkout_request_id={checkout_request_id}, reference={reference}, provider_amount={provider_amount}, expected_amount={expected_amount}")
                    return {"status": "ignored", "reason": "amount_mismatch"}

            mpesa_receipt = payload.MpesaReceiptNumber or bambastack_status.get("receipt_number")

            if result_code != 0:
                logger.warning(f"Payment webhook mismatch (Provider PAID but ResultCode!=0): checkout_request_id={checkout_request_id}, reference={reference}")

            event_dto = PaymentEventCreate(
                ride_id=ride_id,
                payment_event_type="PAYMENT_SUCCESS",
                mpesa_receipt=mpesa_receipt,
                phone_number_used=attempt_event.get("phone_number_used"),
                amount=expected_amount,
                raw_callback=raw_callback_dict,
                metadata={"payment_method": "MPESA", "CheckoutRequestID": checkout_request_id, "ResultDesc": result_desc, "provider": "BAMBASTACK"}
            )
        elif provider_status in ("failed", "cancelled"):
            # Payment Failed or Cancelled according to authoritative provider
            if result_code == 0:
                logger.warning(f"Payment webhook success mismatch: checkout_request_id={checkout_request_id}, reference={reference}, provider_status={provider_status}")

            event_dto = PaymentEventCreate(
                ride_id=ride_id,
                payment_event_type="PAYMENT_FAILED",
                phone_number_used=attempt_event.get("phone_number_used"),
                amount=attempt_event.get("amount"),
                raw_callback=raw_callback_dict,
                metadata={"CheckoutRequestID": checkout_request_id, "ResultCode": result_code, "ResultDesc": result_desc, "provider": "BAMBASTACK", "provider_status": provider_status}
            )
        elif provider_status == "pending":
            if result_code == 0:
                logger.warning(f"Payment webhook success mismatch: checkout_request_id={checkout_request_id}, reference={reference}, provider_status={provider_status}")
            return {"status": "ignored", "reason": "provider_status_pending"}
        else:
            logger.warning(f"Unknown BambaStack payment status '{provider_status}' for reference {reference}")
            return {"status": "ignored", "reason": "unknown_provider_status"}

        try:
            inserted_event = await self.payment_repo.insert_payment_event(event_dto)
        except asyncpg.exceptions.RaiseError as e:
            logger.error(f"DB trigger rejected payment callback event: {e}")
            # If already SUCCESS, DB trigger prevents duplicate SUCCESS/ATTEMPT (BR-010/BR-035)
            return {"status": "ignored", "reason": str(e)}

        updated_ride = await self.ride_repo.get_ride(ride_id)
        await self.pubsub.publish(f"ride_{ride_id}", updated_ride.model_dump(mode='json'))

        return {"status": "processed", "event_id": str(inserted_event["id"])}

    async def confirm_cash_payment(self, actor_id: UUID, actor_role: str, ride_id: UUID) -> Dict[str, Any]:
        """
        Confirms cash received by the rider or owner (BR-011).
        Inserts PAYMENT_SUCCESS event with CASH payment method.
        """
        ride = await self.ride_repo.get_ride(ride_id)
        actor_role_upper = actor_role.upper() if actor_role else ""
        if actor_role_upper != "OWNER" and ride.rider_id != actor_id:
            raise UnauthorizedError("Only the assigned rider or owner can confirm cash received (BR-011).")

        if ride.payment_status == "SUCCESS":
            raise RuleViolationError("Payment for this ride has already succeeded.")

        # Get fare amount
        conn_pool = await self.ride_repo._get_pool()
        async with conn_pool.acquire() as conn:
            row = await conn.fetchrow("SELECT fare_amount FROM rides WHERE id = $1", str(ride_id))
            fare_amount = float(row["fare_amount"]) if row and row["fare_amount"] is not None else None

        event_dto = PaymentEventCreate(
            ride_id=ride_id,
            payment_event_type="PAYMENT_SUCCESS",
            amount=fare_amount,
            metadata={"payment_method": "CASH", "amount_paid": fare_amount}
        )

        try:
            inserted_event = await self.payment_repo.insert_payment_event(event_dto)
        except asyncpg.exceptions.RaiseError as e:
            raise RuleViolationError(f"Database rejected payment confirmation: {str(e)}")

        updated_ride = await self.ride_repo.get_ride(ride_id)
        await self.pubsub.publish(f"ride_{ride_id}", updated_ride.model_dump(mode='json'))

        return {"status": "success", "event_id": str(inserted_event["id"])}

    async def record_cash_dispute(self, actor_id: UUID, actor_role: str, ride_id: UUID, reason: str) -> Dict[str, Any]:
        """
        Records a cash payment dispute (BR-011 / BR-009).
        Refusal of cash payment sets payment_status=DISPUTED, but does NOT block ride.status from being COMPLETED.
        """
        ride = await self.ride_repo.get_ride(ride_id)
        actor_role_upper = actor_role.upper() if actor_role else ""
        if actor_role_upper != "OWNER" and ride.rider_id != actor_id and ride.passenger_id != actor_id:
            raise UnauthorizedError("Not authorized to record cash dispute for this ride.")

        event_dto = PaymentEventCreate(
            ride_id=ride_id,
            payment_event_type="PAYMENT_DISPUTED",
            metadata={"payment_method": "CASH", "disputed_by": str(actor_id), "reason": reason}
        )

        try:
            inserted_event = await self.payment_repo.insert_payment_event(event_dto)
        except asyncpg.exceptions.RaiseError as e:
            raise RuleViolationError(f"Database rejected dispute event: {str(e)}")

        updated_ride = await self.ride_repo.get_ride(ride_id)
        await self.pubsub.publish(f"ride_{ride_id}", updated_ride.model_dump(mode='json'))

        return {"status": "disputed", "event_id": str(inserted_event["id"])}

    async def record_manual_refund(self, owner_id: UUID, owner_role: str, ride_id: UUID, reason: str) -> Dict[str, Any]:
        """
        Records a manual owner refund (REFUND_RECORDED event). No automated reversal logic.
        Requires rides.payment_status='SUCCESS' per DB CHECK constraint chk_refund_requires_success.
        """
        owner_role_upper = owner_role.upper() if owner_role else ""
        if owner_role_upper != "OWNER":
            raise UnauthorizedError("Only the owner can record a manual refund.")

        ride = await self.ride_repo.get_ride(ride_id)
        if ride.payment_status != "SUCCESS":
            raise RuleViolationError("Refund requires payment_status = SUCCESS (BR-010).")

        event_dto = PaymentEventCreate(
            ride_id=ride_id,
            payment_event_type="REFUND_RECORDED",
            metadata={"refunded_by": str(owner_id), "reason": reason}
        )

        try:
            inserted_event = await self.payment_repo.insert_payment_event(event_dto)
        except (asyncpg.exceptions.RaiseError, asyncpg.exceptions.CheckViolationError) as e:
            raise RuleViolationError(f"Database rejected refund event: {str(e)}")

        updated_ride = await self.ride_repo.get_ride(ride_id)
        await self.pubsub.publish(f"ride_{ride_id}", updated_ride.model_dump(mode='json'))

        return {"status": "refunded", "event_id": str(inserted_event["id"])}

    async def reconcile_pending_payments(self, timeout_seconds: int = 90) -> Dict[str, Any]:
        """
        Reconciles pending STK push payments by polling BambaStack payment status
        for attempts past the timeout window (BR-010).
        Maps BambaStack statuses (paid/failed/cancelled) to 7s payment events.
        """
        pending_attempts = await self.payment_repo.get_pending_stk_payments(timeout_seconds=timeout_seconds)
        results = []

        for attempt in pending_attempts:
            ride_id = UUID(str(attempt["ride_id"]))
            # Use ride_id as the BambaStack reference (same as used in send_stk_push)
            reference = str(ride_id)

            try:
                bambastack_status = await self.bambastack.get_payment_status(reference)
                provider_status = str(bambastack_status.get("status", "")).lower()

                if provider_status == "paid":
                    event_dto = PaymentEventCreate(
                        ride_id=ride_id,
                        payment_event_type="PAYMENT_SUCCESS",
                        phone_number_used=attempt.get("phone_number_used"),
                        amount=float(attempt["amount"]) if attempt.get("amount") else None,
                        raw_callback=bambastack_status,
                        metadata={"payment_method": "MPESA", "provider": "BAMBASTACK", "reconciled": True, "reference": reference}
                    )
                elif provider_status in ("failed", "cancelled"):
                    event_dto = PaymentEventCreate(
                        ride_id=ride_id,
                        payment_event_type="PAYMENT_FAILED",
                        phone_number_used=attempt.get("phone_number_used"),
                        amount=float(attempt["amount"]) if attempt.get("amount") else None,
                        raw_callback=bambastack_status,
                        metadata={"provider": "BAMBASTACK", "provider_status": provider_status, "reconciled": True, "reference": reference}
                    )
                elif provider_status == "pending":
                    # Still pending at provider — skip, will be picked up next sweep
                    results.append({"ride_id": str(ride_id), "status": "still_pending"})
                    continue
                else:
                    # Unknown provider status — log and skip safely
                    logger.warning(f"Unknown BambaStack payment status '{provider_status}' for ride {ride_id}")
                    results.append({"ride_id": str(ride_id), "status": "unknown_provider_status", "provider_status": provider_status})
                    continue

                inserted = await self.payment_repo.insert_payment_event(event_dto)
                updated_ride = await self.ride_repo.get_ride(ride_id)
                await self.pubsub.publish(f"ride_{ride_id}", updated_ride.model_dump(mode='json'))
                results.append({"ride_id": str(ride_id), "status": "reconciled", "event_type": event_dto.payment_event_type})
            except Exception as e:
                logger.error(f"Reconciliation error for ride {ride_id}: {e}")
                results.append({"ride_id": str(ride_id), "status": "failed", "error": str(e)})

        return {"reconciled_count": len(results), "results": results}

    async def get_payment_status(self, passenger_id: UUID, ride_id: UUID) -> PaymentStatusResponse:
        """
        Returns a read-only payment state snapshot for fallback polling (BR-010).
        Enforces ownership: only the ride's passenger may poll.
        is_terminal is computed server-side — callers must stop polling when True.
        """
        ride = await self.ride_repo.get_ride(ride_id)
        if ride.passenger_id != passenger_id:
            raise UnauthorizedError(f"Passenger {passenger_id} is not authorized to poll payment status for ride {ride_id}")

        # Extract payment_method from the latest event metadata (MPESA, CASH, etc.)
        payment_method: str | None = None
        latest_attempt = await self.payment_repo.get_latest_payment_attempt(ride_id)
        if latest_attempt:
            metadata = latest_attempt.get("metadata") or {}
            payment_method = metadata.get("payment_method")

        updated_at_str: str | None = None
        if ride.updated_at:
            updated_at_str = ride.updated_at.isoformat()

        return PaymentStatusResponse(
            ride_id=ride_id,
            payment_status=ride.payment_status,
            payment_method=payment_method,
            updated_at=updated_at_str,
            is_terminal=ride.payment_status in _TERMINAL_PAYMENT_STATUSES,
        )
