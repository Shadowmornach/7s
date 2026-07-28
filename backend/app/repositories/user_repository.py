from uuid import UUID
import uuid
from typing import Optional
from app.db.connection import db

# In-memory user cache for development/mocking
_USERS_MEM_DB = {
    "+254712345678": {
        "id": uuid.UUID("77777777-7777-7777-7777-777777777777"),
        "phone_number": "+254712345678",
        "role": "PASSENGER",
        "status": "ACTIVE"
    }
}

_INVALIDATED_TOKENS_MEM = set()

class UserRepository:
    async def get_user_by_phone(self, phone_number: str) -> Optional[dict]:
        if not db.pool:
            return _USERS_MEM_DB.get(phone_number)
        conn = await db.get_connection()
        try:
            row = await conn.fetchrow(
                "SELECT id, phone_number, role FROM users WHERE phone_number = $1",
                phone_number
            )
            if row:
                user = dict(row)
                # Keep status in-memory for testing if column is not present
                mem_user = _USERS_MEM_DB.get(phone_number, {})
                user["status"] = mem_user.get("status", "ACTIVE")
                return user
            return None
        except Exception:
            return _USERS_MEM_DB.get(phone_number)
        finally:
            await db.pool.release(conn)

    async def get_user_by_id(self, user_id: UUID) -> Optional[dict]:
        if not db.pool:
            for u in _USERS_MEM_DB.values():
                if u["id"] == user_id:
                    return u
            return None
        conn = await db.get_connection()
        try:
            row = await conn.fetchrow(
                "SELECT id, phone_number, role FROM users WHERE id = $1",
                str(user_id)
            )
            if row:
                user = dict(row)
                mem_user = _USERS_MEM_DB.get(user["phone_number"], {})
                user["status"] = mem_user.get("status", "ACTIVE")
                return user
            return None
        except Exception:
            for u in _USERS_MEM_DB.values():
                if u["id"] == user_id:
                    return u
            return None
        finally:
            await db.pool.release(conn)

    async def create_user(self, phone_number: str, role: str, status: str = "INACTIVE") -> dict:
        user_id = uuid.uuid4()
        normalized_role = role.upper()
        user_data = {
            "id": user_id,
            "phone_number": phone_number,
            "role": normalized_role,
            "status": status
        }
        # Save to memory cache
        _USERS_MEM_DB[phone_number] = user_data
        
        if not db.pool:
            return user_data
        conn = await db.get_connection()
        try:
            await conn.execute(
                "INSERT INTO users (id, phone_number, role) VALUES ($1, $2, $3)",
                str(user_id), phone_number, normalized_role
            )
            return user_data
        except Exception:
            return user_data
        finally:
            await db.pool.release(conn)

    async def update_user_status(self, phone_number: str, status: str) -> None:
        if phone_number in _USERS_MEM_DB:
            _USERS_MEM_DB[phone_number]["status"] = status

    async def is_refresh_token_invalidated(self, token_hash: str) -> bool:
        if not db.pool:
            return token_hash in _INVALIDATED_TOKENS_MEM
        conn = await db.get_connection()
        try:
            row = await conn.fetchrow(
                "SELECT token_hash FROM invalidated_refresh_tokens WHERE token_hash = $1",
                token_hash
            )
            return row is not None
        except Exception:
            return token_hash in _INVALIDATED_TOKENS_MEM
        finally:
            await db.pool.release(conn)

    async def invalidate_refresh_token(self, token_hash: str) -> None:
        _INVALIDATED_TOKENS_MEM.add(token_hash)
        if not db.pool:
            return
        conn = await db.get_connection()
        try:
            await conn.execute(
                "INSERT INTO invalidated_refresh_tokens (token_hash) VALUES ($1) ON CONFLICT DO NOTHING",
                token_hash
            )
        except Exception:
            pass
        finally:
            await db.pool.release(conn)
