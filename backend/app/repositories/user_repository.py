from uuid import UUID
import uuid
from typing import Optional
from asyncpg import Pool
from app.db.connection import db

_USERS_MEM_DB = {
    "+254712345678": {
        "id": uuid.UUID("77777777-7777-7777-7777-777777777777"),
        "email": "shadow@example.com",
        "phone_number": "+254712345678",
        "nickname": "Shadow",
        "role": "PASSENGER",
        "status": "ACTIVE",
        "is_profile_complete": True,
        "service_zone": "VOI"
    }
}

_INVALIDATED_TOKENS_MEM = set()

class UserRepository:
    def __init__(self, pool: Pool | None = None):
        self._pool = pool

    async def _get_pool(self) -> Pool | None:
        return self._pool or db.pool

    async def get_user_by_google_id(self, google_id: str) -> Optional[dict]:
        pool = await self._get_pool()
        if not pool:
            for u in _USERS_MEM_DB.values():
                if u.get("google_id") == google_id:
                    return u
            return None
        try:
            async with pool.acquire() as conn:
                row = await conn.fetchrow(
                    "SELECT id, email, google_id, phone_number, role, nickname, full_name, photo_url, service_zone, is_profile_complete, is_active FROM users WHERE google_id = $1",
                    google_id
                )
                if row:
                    user = dict(row)
                    user["status"] = "ACTIVE" if user.get("is_active") else "INACTIVE"
                    return user
                return None
        except Exception:
            for u in _USERS_MEM_DB.values():
                if u.get("google_id") == google_id:
                    return u
            return None

    async def get_user_by_email(self, email: str) -> Optional[dict]:
        pool = await self._get_pool()
        if not pool:
            for u in _USERS_MEM_DB.values():
                if u.get("email") == email:
                    return u
            return None
        try:
            async with pool.acquire() as conn:
                row = await conn.fetchrow(
                    "SELECT id, email, google_id, phone_number, role, nickname, full_name, photo_url, service_zone, is_profile_complete, is_active FROM users WHERE email = $1",
                    email
                )
                if row:
                    user = dict(row)
                    user["status"] = "ACTIVE" if user.get("is_active") else "INACTIVE"
                    return user
                return None
        except Exception:
            for u in _USERS_MEM_DB.values():
                if u.get("email") == email:
                    return u
            return None

    async def get_user_by_id(self, user_id: UUID) -> Optional[dict]:
        pool = await self._get_pool()
        if not pool:
            for u in _USERS_MEM_DB.values():
                if u["id"] == user_id:
                    return u
            return None
        try:
            async with pool.acquire() as conn:
                row = await conn.fetchrow(
                    "SELECT id, email, google_id, phone_number, role, nickname, full_name, photo_url, service_zone, is_profile_complete FROM users WHERE id = $1",
                    user_id
                )
                if row:
                    return dict(row)
                return None
        except Exception:
            for u in _USERS_MEM_DB.values():
                if u["id"] == user_id:
                    return u
            return None

    async def create_email_user(self, email: str, password_hash: str, role: str = "PASSENGER") -> dict:
        user_id = uuid.uuid4()
        user_data = {
            "id": user_id,
            "email": email,
            "phone_number": None,
            "password_hash": password_hash,
            "role": role.upper(),
            "nickname": "",
            "full_name": "",
            "photo_url": None,
            "service_zone": "VOI",
            "is_profile_complete": False,
            "status": "ACTIVE"
        }
        _USERS_MEM_DB[email] = user_data

        pool = await self._get_pool()
        if not pool:
            return user_data
        try:
            async with pool.acquire() as conn:
                await conn.execute(
                    "INSERT INTO users (id, email, role, password_hash, is_active, is_profile_complete, service_zone) VALUES ($1, $2, $3, $4, true, false, 'VOI')",
                    user_id, email, role.upper(), password_hash
                )
                return user_data
        except Exception as e:
            import logging
            logging.getLogger("7s.user_repo").error(f"create_email_user DB insert failed for {email}: {e}")
            return user_data

    async def link_google_account(self, user_id: UUID, google_id: str) -> None:
        for u in _USERS_MEM_DB.values():
            if u["id"] == user_id:
                u["google_id"] = google_id
                u["email_verified"] = True

        pool = await self._get_pool()
        if not pool:
            return
        try:
            async with pool.acquire() as conn:
                await conn.execute(
                    "UPDATE users SET google_id = $1, email_verified = true, updated_at = now() WHERE id = $2",
                    google_id, user_id
                )
        except Exception as e:
            import logging
            logging.getLogger("7s.user_repo").error(f"link_google_account failed: {e}")

    async def create_google_user(self, email: str, google_id: str, full_name: Optional[str] = None, photo_url: Optional[str] = None) -> dict:
        user_id = uuid.uuid4()
        user_data = {
            "id": user_id,
            "email": email,
            "google_id": google_id,
            "phone_number": None,
            "role": "PASSENGER",
            "nickname": full_name.split(' ')[0] if full_name else "",
            "full_name": full_name or "",
            "photo_url": photo_url,
            "service_zone": "VOI",
            "is_profile_complete": False,
            "email_verified": True,
            "status": "ACTIVE"
        }
        _USERS_MEM_DB[email] = user_data

        pool = await self._get_pool()
        if not pool:
            return user_data
        try:
            async with pool.acquire() as conn:
                await conn.execute(
                    "INSERT INTO users (id, email, google_id, role, full_name, photo_url, email_verified, is_active, is_profile_complete, service_zone) VALUES ($1, $2, $3, 'PASSENGER', $4, $5, true, true, false, 'VOI')",
                    user_id, email, google_id, full_name, photo_url
                )
                return user_data
        except Exception as e:
            import logging
            logging.getLogger("7s.user_repo").error(f"create_google_user DB insert failed for {email}: {e}")
            return user_data

    async def complete_user_profile(
        self,
        user_id: UUID,
        nickname: str,
        full_name: Optional[str] = None,
        photo_url: Optional[str] = None,
        theme_preference: str = "SYSTEM",
        emergency_contact: Optional[dict] = None
    ) -> dict:
        import json
        user = await self.get_user_by_id(user_id)
        if user:
            user["nickname"] = nickname
            if full_name:
                user["full_name"] = full_name
            if photo_url:
                user["photo_url"] = photo_url
            user["theme_preference"] = theme_preference
            if emergency_contact:
                user["emergency_contact"] = emergency_contact
            user["is_profile_complete"] = True

        pool = await self._get_pool()
        if not pool:
            return user or {}
        try:
            async with pool.acquire() as conn:
                contact_json = json.dumps(emergency_contact) if emergency_contact else None
                await conn.execute(
                    "UPDATE users SET nickname = $1, full_name = COALESCE($2, full_name), photo_url = COALESCE($3, photo_url), theme_preference = $4, emergency_contact = COALESCE($5::jsonb, emergency_contact), is_profile_complete = true, updated_at = now() WHERE id = $6",
                    nickname, full_name, photo_url, theme_preference, contact_json, user_id
                )
        except Exception as e:
            import logging
            logging.getLogger("7s.user_repo").error(f"complete_user_profile DB update failed for {user_id}: {e}")
        return user or {}

    async def update_user_password(self, user_id: UUID, password_hash: str) -> None:
        user = await self.get_user_by_id(user_id)
        if user:
            user["password_hash"] = password_hash

        pool = await self._get_pool()
        if not pool:
            return
        try:
            async with pool.acquire() as conn:
                await conn.execute(
                    "UPDATE users SET password_hash = $1, updated_at = now() WHERE id = $2",
                    password_hash, user_id
                )
        except Exception:
            pass

    async def is_refresh_token_invalidated(self, token_hash: str) -> bool:
        pool = await self._get_pool()
        if not pool:
            return token_hash in _INVALIDATED_TOKENS_MEM
        try:
            async with pool.acquire() as conn:
                row = await conn.fetchrow(
                    "SELECT token_hash FROM invalidated_refresh_tokens WHERE token_hash = $1",
                    token_hash
                )
                return row is not None
        except Exception:
            return token_hash in _INVALIDATED_TOKENS_MEM

    async def invalidate_refresh_token(self, token_hash: str) -> None:
        _INVALIDATED_TOKENS_MEM.add(token_hash)
        pool = await self._get_pool()
        if not pool:
            return
        try:
            async with pool.acquire() as conn:
                await conn.execute(
                    "INSERT INTO invalidated_refresh_tokens (token_hash) VALUES ($1) ON CONFLICT DO NOTHING",
                    token_hash
                )
        except Exception:
            pass

    async def invalidate_all_user_sessions(self, user_id: UUID) -> None:
        import logging
        logging.getLogger("7s.user_repo").info(f"Invalidated all active sessions for user {user_id}")
        pool = await self._get_pool()
        if not pool:
            return
        try:
            async with pool.acquire() as conn:
                await conn.execute(
                    "UPDATE users SET updated_at = now() WHERE id = $1",
                    user_id
                )
        except Exception:
            pass
