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

# Supabase Auth JWKS Client
SUPABASE_JWKS_URI = "https://gwrroyzilnjpdntaybpk.supabase.co/auth/v1/.well-known/jwks.json"
SUPABASE_ISSUER = "https://gwrroyzilnjpdntaybpk.supabase.co/auth/v1"
jwks_client = jwt.PyJWKClient(SUPABASE_JWKS_URI)

def decode_supabase_token(token: str) -> dict:
    try:
        unverified_header = jwt.get_unverified_header(token)
        if unverified_header.get("alg") != "ES256":
            raise RuleViolationError("Invalid token algorithm. Expected ES256.")
            
        signing_key = jwks_client.get_signing_key_from_jwt(token)
        
        payload = jwt.decode(
            token,
            signing_key.key,
            algorithms=["ES256"],
            issuer=SUPABASE_ISSUER,
            audience="authenticated"
        )
        
        sub = payload.get("sub")
        if not sub:
            raise RuleViolationError("Missing subject in token.")
            
        import uuid
        try:
            uuid.UUID(sub)
        except ValueError:
            raise RuleViolationError("Invalid subject format in token.")
            
        return payload
    except jwt.PyJWKClientError:
        raise RuleViolationError("Unable to fetch JWKS to verify token.")
    except jwt.ExpiredSignatureError:
        raise RuleViolationError("Token has expired.")
    except jwt.InvalidTokenError:
        raise RuleViolationError("Invalid token.")

def verify_auth_token(token: str) -> dict:
    try:
        header = jwt.get_unverified_header(token)
    except jwt.DecodeError:
        raise RuleViolationError("Malformed token.")

    alg = header.get("alg")
    
    if alg == "ES256":
        payload = decode_supabase_token(token)
        return {
            "sub": payload["sub"],
            "provider": "supabase"
        }
    elif alg == "HS256":
        payload = decode_token(token)
        return {
            "sub": payload["sub"],
            "role": payload.get("role"),
            "provider": "legacy"
        }
    else:
        raise RuleViolationError(f"Unsupported token algorithm: {alg}")
