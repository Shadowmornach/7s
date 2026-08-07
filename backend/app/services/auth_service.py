from uuid import UUID
import logging
import time
import secrets
from app.core.config import settings
from app.repositories.user_repository import UserRepository
from app.schemas.auth import Token, UserResponse
from app.core.jwt_auth import create_access_token, create_refresh_token, hash_password, verify_password
from app.domain.exceptions import RuleViolationError
from app.core.metrics import auth_failures_total

logger = logging.getLogger("7s.auth")

_PASSWORD_RESET_STORE = {}

class AuthService:
    def __init__(self, user_repo: UserRepository):
        self.user_repo = user_repo

    async def register_with_email(self, email: str, password: str) -> Token:
        existing = await self.user_repo.get_user_by_email(email)
        if existing:
            raise RuleViolationError("This email is already registered. Please sign in instead.")

        pw_hash = hash_password(password)
        user = await self.user_repo.create_email_user(email=email, password_hash=pw_hash, role="PASSENGER")

        access_token = create_access_token(subject=user["id"], role=user["role"])
        refresh_token = create_refresh_token(subject=user["id"], role=user["role"])
        return Token(access_token=access_token, refresh_token=refresh_token)

    async def login_with_email(self, email: str, password: str) -> Token:
        user = await self.user_repo.get_user_by_email(email)
        if not user:
            auth_failures_total.labels(reason="user_not_found").inc()
            raise RuleViolationError("Invalid email or password")
        
        stored_hash = user.get("password_hash")
        if not stored_hash or not verify_password(password, stored_hash):
            auth_failures_total.labels(reason="invalid_password").inc()
            raise RuleViolationError("Invalid email or password")

        access_token = create_access_token(subject=user["id"], role=user["role"])
        refresh_token = create_refresh_token(subject=user["id"], role=user["role"])
        return Token(access_token=access_token, refresh_token=refresh_token)

    async def complete_profile(
        self,
        user_id: UUID,
        nickname: str,
        full_name: str | None = None,
        photo_url: str | None = None,
        theme_preference: str | None = "SYSTEM",
        emergency_contact: dict | None = None
    ) -> dict:
        return await self.user_repo.complete_user_profile(
            user_id=user_id,
            nickname=nickname,
            full_name=full_name,
            photo_url=photo_url,
            theme_preference=theme_preference or "SYSTEM",
            emergency_contact=emergency_contact
        )

    async def request_password_reset_otp(self, email: str) -> str | None:
        user = await self.user_repo.get_user_by_email(email)
        if not user:
            logger.info(f"Password reset silently requested for non-existent email: {email}")
            return None

        import random, hashlib
        otp_code = f"{random.randint(100000, 999999)}"
        otp_hash = hashlib.sha256(otp_code.encode("utf-8")).hexdigest()

        # Invalidate any previous active reset session for this email immediately
        _PASSWORD_RESET_STORE[email] = {
            "otp_code_hash": otp_hash,
            "raw_otp_dev": otp_code,  # For logger inspection in test/dev environments
            "expires_at": time.time() + 600,
            "verified": False,
            "is_used": False,
            "attempts": 0,
            "user_id": user["id"]
        }
        logger.info(f"[EMAIL SERVICE] Hashed 6-digit OTP [{otp_code}] generated for password reset to {email}")
        return otp_code

    async def verify_password_reset_otp(self, email: str, otp: str) -> bool:
        import hashlib
        stored = _PASSWORD_RESET_STORE.get(email)
        if not stored or time.time() > stored["expires_at"] or stored.get("is_used"):
            _PASSWORD_RESET_STORE.pop(email, None)
            raise RuleViolationError("Verification code has expired or is invalid. Please request a new one.")

        if stored["attempts"] >= 5:
            _PASSWORD_RESET_STORE.pop(email, None)
            raise RuleViolationError("Too many incorrect attempts. Please request a new verification code.")

        input_hash = hashlib.sha256(otp.strip().encode("utf-8")).hexdigest()
        if stored["otp_code_hash"] != input_hash:
            stored["attempts"] += 1
            remaining = 5 - stored["attempts"]
            if remaining <= 0:
                _PASSWORD_RESET_STORE.pop(email, None)
                raise RuleViolationError("Too many incorrect attempts. Please request a new verification code.")
            raise RuleViolationError(f"Invalid verification code. {remaining} attempt(s) remaining.")

        stored["verified"] = True
        logger.info(f"Password reset OTP successfully verified for {email}")
        return True

    async def reset_password_with_otp(self, email: str, otp: str, new_password: str) -> bool:
        stored = _PASSWORD_RESET_STORE.get(email)
        if not stored or stored.get("is_used"):
            raise RuleViolationError("Verification code has expired or is invalid. Please request a new one.")

        if not stored.get("verified"):
            await self.verify_password_reset_otp(email, otp)
            stored = _PASSWORD_RESET_STORE.get(email)

        user = await self.user_repo.get_user_by_email(email)
        if not user:
            _PASSWORD_RESET_STORE.pop(email, None)
            raise RuleViolationError("No account was found with this email.")

        pw_hash = hash_password(new_password)
        await self.user_repo.update_user_password(user["id"], pw_hash)
        
        # Mark OTP as used and destroy reset session
        stored["is_used"] = True
        _PASSWORD_RESET_STORE.pop(email, None)

        # Force logout on every device by invalidating active user sessions/tokens
        await self.user_repo.invalidate_all_user_sessions(user["id"])

        logger.info(f"Password successfully reset for {email}. All active sessions invalidated.")
        return True

    async def get_user(self, user_id: UUID) -> UserResponse:
        user = await self.user_repo.get_user_by_id(user_id)
        if not user:
            raise RuleViolationError("User not found")

        return UserResponse(
            id=user["id"],
            email=user.get("email"),
            phone_number=user.get("phone_number"),
            nickname=user.get("nickname"),
            full_name=user.get("full_name"),
            photo_url=user.get("photo_url"),
            service_zone=user.get("service_zone", "VOI"),
            is_profile_complete=user.get("is_profile_complete", False),
            role=user["role"]
        )
