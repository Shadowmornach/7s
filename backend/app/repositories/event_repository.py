import json
from decimal import Decimal
from uuid import UUID
from typing import Dict, Any, Optional
from asyncpg import Pool
from app.db.connection import db

class EventRepository:
    def __init__(self, pool: Pool | None = None):
        self._pool = pool

    async def _get_pool(self) -> Pool:
        pool = self._pool or db.pool
        if not pool:
            await db.connect()
            pool = db.pool
        if not pool:
            raise RuntimeError("Database pool is not initialized.")
        return pool

    async def append_ride_event(self, ride_id: UUID, event_type: str, actor_id: UUID, lat: Optional[float] = None, lng: Optional[float] = None, metadata: Dict[str, Any] = None):
        pool = await self._get_pool()
        lat_dec = Decimal(str(lat)) if lat is not None else None
        lng_dec = Decimal(str(lng)) if lng is not None else None
        async with pool.acquire() as conn:
            await conn.execute(
                """
                INSERT INTO ride_events (ride_id, ride_event_type, actor_id, lat, lng, metadata)
                VALUES ($1, $2, $3, $4, $5, $6)
                """,
                str(ride_id), event_type, str(actor_id), lat_dec, lng_dec, json.dumps(metadata or {})
            )

    async def append_payment_event(self, ride_id: UUID, event_type: str, status: str, metadata: Dict[str, Any] = None):
        # Implementation postponed per instructions (No Payments)
        pass

    async def append_sos_alert(self, ride_id: UUID, triggered_by: UUID, severity: str, lat: Optional[float] = None, lng: Optional[float] = None):
        pool = await self._get_pool()
        lat_dec = Decimal(str(lat)) if lat is not None else None
        lng_dec = Decimal(str(lng)) if lng is not None else None
        async with pool.acquire() as conn:
            await conn.execute(
                """
                INSERT INTO sos_alerts (ride_id, triggered_by, severity, lat, lng)
                VALUES ($1, $2, $3, $4, $5)
                """,
                str(ride_id), str(triggered_by), severity, lat_dec, lng_dec
            )

    async def append_cash_handover(self, rider_id: UUID, expected_cash: float, actual_cash: float, received_by: UUID):
        # Implementation postponed per instructions (No Payments in Stage 1)
        pass
