from typing import Optional, Any
from app.db.connection import db

class ConfigRepository:
    def __init__(self, pool):
        self.pool = pool

    async def get_config_value(self, key: str, default: Any = None) -> Any:
        query = "SELECT value FROM configuration WHERE key = $1"
        async with self.pool.acquire() as conn:
            row = await conn.fetchrow(query, key)
            if row and row["value"] is not None:
                # Assuming values are stored as strings or jsonb.
                # In 008_supporting.sql it's likely a JSONB or text field.
                # If text, we can cast it in the caller.
                return row["value"]
            return default
