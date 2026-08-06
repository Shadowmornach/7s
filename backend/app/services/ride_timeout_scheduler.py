import asyncio
import logging
from asyncpg import Pool
from app.db.connection import db
from app.core.config import settings
from app.core.metrics import ride_timeouts_total

logger = logging.getLogger("7s.timeout")

class TimeoutService:
    def __init__(self, pool: Pool | None = None):
        self.is_running = False
        self._task = None
        self._pool = pool

    async def _get_pool(self) -> Pool:
        pool = self._pool or db.pool
        if not pool:
            await db.connect()
            pool = db.pool
        if not pool:
            raise RuntimeError("Database pool is not initialized.")
        return pool

    async def _sweep(self):
        pool = await self._get_pool()
        async with pool.acquire() as conn:
            # Cancel rides stuck in REQUESTED for too long
            # Using 011_triggers.sql state machine, we must INSERT a ride_event (BR-022)
            # instead of directly updating the rides table.
            # Gate 6: FOR UPDATE SKIP LOCKED prevents distributed collision
            timeout_seconds = settings.RIDE_TIMEOUT_SECONDS
            result = await conn.execute(
                """
                INSERT INTO ride_events (ride_id, ride_event_type, actor_id, metadata)
                SELECT id, 'RIDE_CANCELLED', '00000000-0000-0000-0000-000000000000', '{"cancelled_by": "SYSTEM", "cancel_reason": "SYSTEM_TIMEOUT"}'::jsonb
                FROM rides 
                WHERE status = 'REQUESTED' 
                AND created_at < NOW() - INTERVAL '1 second' * $1
                FOR UPDATE SKIP LOCKED
                """,
                timeout_seconds
            )
            
            # The result is like 'INSERT 0 N'
            updated_count = int(result.split(" ")[2])
            if updated_count > 0:
                ride_timeouts_total.inc(updated_count)
                logger.info(f"Auto-cancelled {updated_count} stuck rides")

    async def _run(self):
        while self.is_running:
            try:
                # Gate 7: Encapsulate DB connect and sweep in a try-except to prevent silent crashes
                await self._sweep()
            except Exception as e:
                logger.error("Error during timeout sweep (Will retry)", exc_info=True)
            
            await asyncio.sleep(settings.TIMEOUT_SWEEP_INTERVAL_SECONDS)

    def start(self):
        if not self.is_running:
            self.is_running = True
            self._task = asyncio.create_task(self._run())
            logger.info("Timeout sweep service started")

    async def stop(self):
        self.is_running = False
        if self._task:
            self._task.cancel()
            try:
                await self._task
            except asyncio.CancelledError:
                pass
            logger.info("Timeout sweep service stopped")
