from pydantic import BaseModel
from uuid import UUID
from enum import Enum

class UserRole(str, Enum):
    OWNER = "OWNER"
    RIDER = "RIDER"
    PASSENGER = "PASSENGER"

class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"

class TokenPayload(BaseModel):
    sub: str | None = None
    role: str | None = None

class OTPRequest(BaseModel):
    phone_number: str

class OTPVerifyRequest(BaseModel):
    phone_number: str
    otp: str

class RegisterRequest(BaseModel):
    phone_number: str
    role: str

class UserResponse(BaseModel):
    id: UUID
    phone_number: str
    role: str
