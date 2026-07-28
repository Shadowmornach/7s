from pydantic import BaseModel, ConfigDict, Field
from uuid import UUID
from datetime import datetime
from typing import Optional
from decimal import Decimal
from enum import Enum

class PlaceType(str, Enum):
    SYSTEM = "SYSTEM"
    OWNER = "OWNER"
    USER = "USER"

class PlaceOrigin(str, Enum):
    MANUAL = "MANUAL"
    GOOGLE = "GOOGLE"
    OSM = "OSM"
    GPS = "GPS"

class PlaceBase(BaseModel):
    name: str = Field(..., max_length=255)
    latitude: Decimal = Field(..., ge=-90, le=90)
    longitude: Decimal = Field(..., ge=-180, le=180)

class PlaceCreate(PlaceBase):
    place_type: PlaceType
    origin: PlaceOrigin = PlaceOrigin.MANUAL

class PlaceUpdate(BaseModel):
    name: Optional[str] = Field(None, max_length=255)
    active: Optional[bool] = None

class PlaceResponse(PlaceBase):
    id: UUID
    place_type: PlaceType
    origin: PlaceOrigin
    created_by: UUID
    usage_count: int
    active: bool
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
