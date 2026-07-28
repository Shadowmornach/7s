from pydantic import BaseModel, ConfigDict, Field
from uuid import UUID
from datetime import datetime
from typing import Optional
from decimal import Decimal

class FareTemplateBase(BaseModel):
    fare: Decimal = Field(..., gt=0)
    estimated_distance: Optional[Decimal] = None
    estimated_time: Optional[int] = None
    notes: Optional[str] = None

class FareTemplateCreate(FareTemplateBase):
    from_place_id: UUID
    to_place_id: UUID

class FareTemplateUpdate(BaseModel):
    fare: Optional[Decimal] = Field(None, gt=0)
    estimated_distance: Optional[Decimal] = None
    estimated_time: Optional[int] = None
    active: Optional[bool] = None
    notes: Optional[str] = None

class FareTemplateResponse(FareTemplateBase):
    id: UUID
    from_place_id: UUID
    to_place_id: UUID
    active: bool
    created_at: datetime
    last_updated: datetime

    model_config = ConfigDict(from_attributes=True)

class RouteQuoteRequest(BaseModel):
    pickup_lat: Decimal
    pickup_lng: Decimal
    destination_lat: Decimal
    destination_lng: Decimal
    pickup_place_id: Optional[UUID] = None
    destination_place_id: Optional[UUID] = None

class RouteQuoteResponse(BaseModel):
    fare: Optional[Decimal] = None
    estimated_distance_km: Decimal
    estimated_time_seconds: int
    is_template_match: bool
