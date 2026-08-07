import re
from pydantic import BaseModel, EmailStr, field_validator
from uuid import UUID

def validate_password_strength(v: str) -> str:
    if len(v) < 10:
        raise ValueError('Password must be at least 10 characters long.')
    if not re.search(r'[A-Z]', v):
        raise ValueError('Password must contain at least one uppercase letter.')
    if not re.search(r'[a-z]', v):
        raise ValueError('Password must contain at least one lowercase letter.')
    if not re.search(r'\d', v):
        raise ValueError('Password must contain at least one number.')
    if not re.search(r'[^a-zA-Z0-9]', v):
        raise ValueError('Password must contain at least one special character.')
    return v
from enum import Enum
from typing import Optional

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

class EmailRegisterRequest(BaseModel):
    email: EmailStr
    password: str

    @field_validator('password')
    @classmethod
    def check_password(cls, v: str) -> str:
        return validate_password_strength(v)

class EmailLoginRequest(BaseModel):
    email: EmailStr
    password: str

class CompleteProfileRequest(BaseModel):
    nickname: str
    full_name: Optional[str] = None
    photo_url: Optional[str] = None
    theme_preference: Optional[str] = "SYSTEM"
    emergency_contact: Optional[dict] = None

class PasswordResetRequest(BaseModel):
    email: EmailStr

class VerifyOtpRequest(BaseModel):
    email: EmailStr
    otp: str

class ResetPasswordWithOtpRequest(BaseModel):
    email: EmailStr
    otp: str
    new_password: str

    @field_validator('new_password')
    @classmethod
    def check_password(cls, v: str) -> str:
        return validate_password_strength(v)

class UserResponse(BaseModel):
    id: UUID
    email: Optional[str] = None
    phone_number: Optional[str] = None
    nickname: Optional[str] = None
    full_name: Optional[str] = None
    photo_url: Optional[str] = None
    service_zone: str = "VOI"
    is_profile_complete: bool = False
    role: str
    theme_preference: str = "SYSTEM"
    emergency_contact: Optional[dict] = None
