from datetime import datetime, timedelta, timezone

import jwt
from typing import Any
from app.core.config import settings
from app.domain.exceptions import RuleViolationError

import bcrypt

def hash_password(password: str) -> str:
    # bcrypt.hashpw requires bytes, and returns bytes. We store it as a string in the DB.
    salt = bcrypt.gensalt()
    hashed = bcrypt.hashpw(password.encode('utf-8'), salt)
    return hashed.decode('utf-8')

def verify_password(plain_password: str, hashed_password: str) -> bool:
    try:
        return bcrypt.checkpw(plain_password.encode('utf-8'), hashed_password.encode('utf-8'))
    except ValueError:
        return False

def create_access_token(subject: str | Any, role: str) -> str:
    expires_delta = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    expire = datetime.now(timezone.utc) + expires_delta
    to_encode = {"sub": str(subject), "role": role, "type": "access", "exp": expire}
    encoded_jwt = jwt.encode(to_encode, settings.JWT_SECRET.get_secret_value(), algorithm=settings.JWT_ALGORITHM)
    return encoded_jwt

def create_refresh_token(subject: str | Any, role: str) -> str:
    expires_delta = timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    expire = datetime.now(timezone.utc) + expires_delta
    to_encode = {"sub": str(subject), "role": role, "type": "refresh", "exp": expire}
    encoded_jwt = jwt.encode(to_encode, settings.JWT_SECRET.get_secret_value(), algorithm=settings.JWT_ALGORITHM)
    return encoded_jwt

def decode_token(token: str, token_type: str = "access") -> dict:
    try:
        payload = jwt.decode(token, settings.JWT_SECRET.get_secret_value(), algorithms=[settings.JWT_ALGORITHM])
        if payload.get("type") != token_type:
            raise RuleViolationError(f"Invalid token type. Expected {token_type}.")
        return payload
    except jwt.ExpiredSignatureError:
        raise RuleViolationError("Token has expired.")
    except jwt.InvalidTokenError:
        raise RuleViolationError("Invalid token.")
