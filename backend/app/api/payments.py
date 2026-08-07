from fastapi import APIRouter, Depends, HTTPException, status, Request
from uuid import UUID
from typing import Dict, Any
from pydantic import BaseModel, Field

from app.schemas.payments import STKPushRequest, BambaStackSTKResponse, BambaStackCallbackPayload, PaymentStatusResponse
from app.schemas.auth import TokenPayload
from app.api.dependencies import get_current_user, require_role, get_payment_service
from app.services.payment_service import PaymentService
from app.domain.exceptions import DomainException, RuleViolationError, UnauthorizedError, ResourceNotFoundError

router = APIRouter(prefix="/payments", tags=["Payments"])

class DisputeCashRequest(BaseModel):
    reason: str = Field(..., min_length=3, description="Reason for cash payment dispute")

class RefundRequest(BaseModel):
    reason: str = Field(..., min_length=3, description="Reason for manual refund")

def _get_authenticated_user(current_user: TokenPayload) -> tuple[UUID, str]:
    if not current_user.sub or not current_user.role:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication token: sub and role claims are required."
        )
    return UUID(current_user.sub), current_user.role

@router.post("/stk-push", response_model=BambaStackSTKResponse)
async def initiate_stk_push(
    payload: STKPushRequest,
    current_user: TokenPayload = Depends(get_current_user),
    payment_service: PaymentService = Depends(get_payment_service)
):
    """
    Initiates an M-PESA STK Push prompt to the passenger's registered or specified mobile number.
    Requires authentication (Passenger).
    """
    user_id, _ = _get_authenticated_user(current_user)
    try:
        return await payment_service.initiate_stk_push(passenger_id=user_id, payload=payload)
    except DomainException as e:
        if e.code == "UNAUTHORIZED":
            status_code = status.HTTP_403_FORBIDDEN
        else:
            status_code = status.HTTP_400_BAD_REQUEST
        raise HTTPException(status_code=status_code, detail={"error_code": e.code, "message": str(e)})

@router.post("/bambastack/webhook")
async def bambastack_webhook(
    payload: BambaStackCallbackPayload,
    payment_service: PaymentService = Depends(get_payment_service)
):
    """
    Production webhook endpoint for BambaStack payment callbacks.
    Called asynchronously by BambaStack when an M-Pesa STK Push is resolved.

    Public URL: https://<7S-BACKEND-DOMAIN>/api/v1/payments/bambastack/webhook

    Security: Strict payload validation, payment correlation, and idempotency.
    BambaStack does not currently document a webhook signature/HMAC mechanism.
    If BambaStack later provides an official authentication mechanism,
    add verification here before processing the callback.

    Idempotency: Duplicate callbacks for the same checkout_request_id are safely
    rejected by the database trigger (BR-010).
    """
    try:
        return await payment_service.handle_bambastack_callback(payload)
    except ResourceNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail={"error_code": "NOT_FOUND", "message": str(e)})
    except DomainException as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail={"error_code": e.code, "message": str(e)})

@router.post("/{ride_id}/confirm-cash")
async def confirm_cash_payment(
    ride_id: UUID,
    current_user: TokenPayload = Depends(get_current_user),
    payment_service: PaymentService = Depends(get_payment_service)
):
    """
    Rider or Owner explicitly confirms cash received for a ride (BR-011).
    """
    user_id, role = _get_authenticated_user(current_user)
    try:
        return await payment_service.confirm_cash_payment(actor_id=user_id, actor_role=role, ride_id=ride_id)
    except DomainException as e:
        status_code = status.HTTP_403_FORBIDDEN if e.code == "UNAUTHORIZED" else status.HTTP_400_BAD_REQUEST
        raise HTTPException(status_code=status_code, detail={"error_code": e.code, "message": str(e)})

@router.post("/{ride_id}/dispute-cash")
async def dispute_cash_payment(
    ride_id: UUID,
    payload: DisputeCashRequest,
    current_user: TokenPayload = Depends(get_current_user),
    payment_service: PaymentService = Depends(get_payment_service)
):
    """
    Records a cash payment dispute (BR-011 / BR-009). Does not block ride completion.
    """
    user_id, role = _get_authenticated_user(current_user)
    try:
        return await payment_service.record_cash_dispute(
            actor_id=user_id,
            actor_role=role,
            ride_id=ride_id,
            reason=payload.reason
        )
    except DomainException as e:
        status_code = status.HTTP_403_FORBIDDEN if e.code == "UNAUTHORIZED" else status.HTTP_400_BAD_REQUEST
        raise HTTPException(status_code=status_code, detail={"error_code": e.code, "message": str(e)})

@router.post("/{ride_id}/refund")
async def record_manual_refund(
    ride_id: UUID,
    payload: RefundRequest,
    current_user: TokenPayload = Depends(require_role(["OWNER"])),
    payment_service: PaymentService = Depends(get_payment_service)
):
    """
    Records a manual owner refund (REFUND_RECORDED). No automated reversal.
    Requires payment_status = SUCCESS (BR-010 / DB CHECK constraint).
    """
    owner_id, role = _get_authenticated_user(current_user)
    try:
        return await payment_service.record_manual_refund(
            owner_id=owner_id,
            owner_role=role,
            ride_id=ride_id,
            reason=payload.reason
        )
    except DomainException as e:
        status_code = status.HTTP_403_FORBIDDEN if e.code == "UNAUTHORIZED" else status.HTTP_400_BAD_REQUEST
        raise HTTPException(status_code=status_code, detail={"error_code": e.code, "message": str(e)})

@router.post("/reconcile")
async def reconcile_pending_payments(
    timeout_seconds: int = 90,
    current_user: TokenPayload = Depends(require_role(["OWNER"])),
    payment_service: PaymentService = Depends(get_payment_service)
):
    """
    Triggers automated reconciliation of pending STK payments past timeout window (BR-010).
    Polls BambaStack payment status API and updates payment status.
    """
    _get_authenticated_user(current_user)
    try:
        return await payment_service.reconcile_pending_payments(timeout_seconds=timeout_seconds)
    except DomainException as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail={"error_code": e.code, "message": str(e)})

@router.get("/{ride_id}/status", response_model=PaymentStatusResponse)
async def get_payment_status(
    ride_id: UUID,
    current_user: TokenPayload = Depends(get_current_user),
    payment_service: PaymentService = Depends(get_payment_service)
):
    """
    Read-only fallback poll endpoint. Returns current payment state for a ride.
    Intended for use when the ride WebSocket is unavailable (reconnect, background resume).
    Flutter must stop polling once is_terminal=True (computed server-side).
    Requires authentication. Passenger ownership enforced.
    """
    user_id, _ = _get_authenticated_user(current_user)
    try:
        return await payment_service.get_payment_status(passenger_id=user_id, ride_id=ride_id)
    except DomainException as e:
        status_code = status.HTTP_403_FORBIDDEN if e.code == "UNAUTHORIZED" else status.HTTP_404_NOT_FOUND
        raise HTTPException(status_code=status_code, detail={"error_code": e.code, "message": str(e)})
