import asyncpg
from typing import Optional
from app.core.config import settings

class Database:
    def __init__(self):
        self.pool: Optional[asyncpg.Pool] = None

    async def connect(self):
        if not self.pool:
            self.pool = await asyncpg.create_pool(
                dsn=settings.DATABASE_URL.get_secret_value(),
                statement_cache_size=0
            )

    async def disconnect(self):
        if self.pool:
            await self.pool.close()
            self.pool = None

    def get_connection(self):
        if not self.pool:
            raise RuntimeError("Database pool is not connected. Call await db.connect() first.")
        return self.pool.acquire()

db = Database()
