from pydantic import BaseModel, Field
from typing import Dict, Any, Optional
from datetime import datetime
from uuid import UUID

class UnifiedEventRequest(BaseModel):
    action: str = Field(..., description="The API action triggering the event, e.g., 'accept_fare'")
    expected_version: int = Field(..., description="The client's known version of the ride for optimistic concurrency")
    metadata: Dict[str, Any] = Field(default_factory=dict, description="Event-specific metadata")

class RideRequestPayload(BaseModel):
    pickup_lat: float
    pickup_lng: float
    destination_lat: float
    destination_lng: float
    pickup_place_id: Optional[UUID] = None
    destination_place_id: Optional[UUID] = None
    preferred_payment_method: Optional[str] = None

class RideResponse(BaseModel):
    id: UUID
    passenger_id: UUID
    rider_id: Optional[UUID]
    status: str
    payment_status: str
    version: int
    active_sos_id: Optional[UUID] = None
    active_sos_severity: Optional[str] = None
    active_sos_status: Optional[str] = None
    created_at: datetime
    updated_at: datetime

class CashHandoverRequest(BaseModel):
    actual_cash: float
    expected_cash: float

class RatingRequest(BaseModel):
    rated_user: UUID
    score: int = Field(..., ge=1, le=5)
    comment: Optional[str] = None

class RiderLocationPayload(BaseModel):
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
