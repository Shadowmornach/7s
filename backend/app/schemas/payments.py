from pydantic import BaseModel, Field
from typing import Optional, Any, Dict
from uuid import UUID

# =====================================================================
# STK PUSH REQUEST (Provider-Neutral — initiated by passenger)
# =====================================================================

class STKPushRequest(BaseModel):
    """
    Request payload initiated by the passenger app to trigger an STK Push.
    """
    ride_id: UUID
    # We do not accept amount here; amount is strictly read from the ride's fare_amount (Security)
    phone_number: Optional[str] = Field(default=None, description="Optional override number. If null, uses passenger registered phone.")

# =====================================================================
# BAMBASTACK STK PUSH RESPONSE
# =====================================================================

class BambaStackSTKResponse(BaseModel):
    """
    Synchronous response from BambaStack when an STK push is successfully queued (HTTP 202).
    Fields match the actual BambaStack API contract.
    """
    transaction_id: str
    checkout_request_id: Optional[str] = None

# =====================================================================
# BAMBASTACK WEBHOOK CALLBACK PAYLOAD
# =====================================================================

class BambaStackCallbackPayload(BaseModel):
    """
    The JSON payload received at the 7s webhook endpoint from BambaStack
    when a payment is resolved (success or failure).

    Contract source: BambaStack_7s_delivery_Collection.json
    """
    checkout_request_id: str
    ResultCode: int
    ResultDesc: str
    MpesaReceiptNumber: Optional[str] = None

# =====================================================================
# INTERNAL PAYMENT EVENT DTO
# =====================================================================

class PaymentEventCreate(BaseModel):
    """
    Internal DTO for creating a new record in payment_events.
    """
    ride_id: UUID
    payment_event_type: str  # Matches payment_event_type Enum (PAYMENT_ATTEMPT, PAYMENT_SUCCESS, PAYMENT_FAILED, PAYMENT_DISPUTED, REFUND_RECORDED)
    mpesa_receipt: Optional[str] = None
    phone_number_used: Optional[str] = None
    amount: Optional[float] = None
    raw_callback: Optional[Dict[str, Any]] = None
    metadata: Optional[Dict[str, Any]] = Field(default_factory=dict)

# =====================================================================
# PAYMENT STATUS POLLING RESPONSE
# =====================================================================

_TERMINAL_PAYMENT_STATUSES = frozenset({"SUCCESS", "FAILED", "DISPUTED", "REFUND_RECORDED"})

class PaymentStatusResponse(BaseModel):
    """
    Read-only snapshot returned by GET /payments/{ride_id}/status.
    Used by Flutter as a fallback when the ride WebSocket is unavailable.
    Flutter must stop polling once is_terminal is True.
    """
    ride_id: UUID
    payment_status: str
    payment_method: Optional[str] = None  # e.g. "MPESA", "CASH" — sourced from latest event metadata
    updated_at: Optional[str] = None      # ISO-8601 UTC timestamp of last rides.updated_at
    is_terminal: bool                     # True when no further state transitions are possible
