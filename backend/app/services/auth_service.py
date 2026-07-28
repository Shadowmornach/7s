from uuid import UUID
import random
import logging
import time
from app.repositories.user_repository import UserRepository
from app.schemas.auth import Token, UserResponse
from app.core.jwt_auth import create_access_token, create_refresh_token
from app.domain.exceptions import RuleViolationError
from app.core.metrics import auth_failures_total

logger = logging.getLogger("7s.auth")

# OTP Store structure: {phone_number: {"otp": str, "expires_at": float, "attempts": int}}
_OTP_STORE = {}

class AuthService:
    def __init__(self, user_repo: UserRepository):
        self.user_repo = user_repo

    async def generate_otp(self, phone_number: str) -> str:
        from app.core.config import settings
        import httpx

        # Generate 6-digit OTP
        otp = str(random.randint(100000, 999999))
        _OTP_STORE[phone_number] = {
            "otp": otp,
            "expires_at": time.time() + 300, # 5 minutes expiry
            "attempts": 0
        }

        # Live SMS delivery via Africa's Talking when configured
        if settings.AT_USERNAME and settings.AT_API_KEY:
            try:
                username = settings.AT_USERNAME
                api_key = settings.AT_API_KEY.get_secret_value()
                endpoint = (
                    "https://api.sandbox.africastalking.com/version1/messaging"
                    if username == "sandbox"
                    else "https://api.africastalking.com/version1/messaging"
                )
                headers = {
                    "Accept": "application/json",
                    "Content-Type": "application/x-www-form-urlencoded",
                    "apiKey": api_key,
                }
                data = {
                    "username": username,
                    "to": phone_number,
                    "message": f"Your 7s login code is: {otp}. Valid for 5 minutes.",
                }
                if settings.AT_SENDER_ID:
                    data["from"] = settings.AT_SENDER_ID

                async with httpx.AsyncClient(timeout=5.0) as client:
                    resp = await client.post(endpoint, headers=headers, data=data)
                    if resp.status_code in (200, 201):
                        logger.info(f"Africa's Talking SMS sent successfully to {phone_number}")
                    else:
                        logger.warning(f"Africa's Talking SMS delivery returned {resp.status_code}: {resp.text}")
            except Exception as e:
                logger.warning(f"Africa's Talking SMS delivery failed: {e}. Falling back to console log.")

        # Always log to console/logger as backup / dev mode
        logger.info(f"[SMS GATEWAY] OTP for {phone_number}: {otp}")
        print(f"[SMS GATEWAY] OTP for {phone_number}: {otp}", flush=True)
        return otp


    async def verify_otp_and_login(self, phone_number: str, otp: str) -> Token:
        stored = _OTP_STORE.get(phone_number)
        if not stored:
            auth_failures_total.labels(reason="no_otp_requested").inc()
            raise RuleViolationError("Invalid phone number or OTP")

        # Expiry Check
        if time.time() > stored["expires_at"]:
            _OTP_STORE.pop(phone_number, None)
            auth_failures_total.labels(reason="expired_otp").inc()
            raise RuleViolationError("OTP has expired")

        # Increment Attempts
        stored["attempts"] += 1
        if stored["attempts"] > 3:
            _OTP_STORE.pop(phone_number, None)
            auth_failures_total.labels(reason="max_retries_exceeded").inc()
            raise RuleViolationError("Max verification attempts exceeded")

        # OTP Match Check
        if stored["otp"] != otp:
            auth_failures_total.labels(reason="invalid_otp").inc()
            raise RuleViolationError("Invalid phone number or OTP")

        # OTP is single-use, remove it immediately upon success
        _OTP_STORE.pop(phone_number, None)

        user = await self.user_repo.get_user_by_phone(phone_number)
        if not user:
            auth_failures_total.labels(reason="user_not_registered").inc()
            raise RuleViolationError("User is not registered")

        # BR-001: Transition user to ACTIVE state upon first successful verification
        if user.get("status") == "INACTIVE":
            await self.user_repo.update_user_status(phone_number, "ACTIVE")

        access_token = create_access_token(subject=user["id"], role=user["role"])
        refresh_token = create_refresh_token(subject=user["id"], role=user["role"])
        
        return Token(access_token=access_token, refresh_token=refresh_token)

    async def get_user(self, user_id: UUID) -> UserResponse:
        user = await self.user_repo.get_user_by_id(user_id)
        if not user:
            raise RuleViolationError("User not found")
            
        return UserResponse(
            id=user["id"],
            phone_number=user["phone_number"],
            role=user["role"]
        )
