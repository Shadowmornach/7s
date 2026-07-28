from typing import List, Dict, Any, Optional
from uuid import UUID
import asyncpg

from app.db.connection import db

class OperationsRepository:
    """
    Persistence layer for Operations, Reports, and Management screens.
    Leverages pre-built database views in 010_views.sql.
    """

    def __init__(self, pool: Optional[asyncpg.Pool] = None):
        self._pool = pool

    async def _get_pool(self) -> asyncpg.Pool:
        pool = self._pool or db.pool
        if not pool:
            await db.connect()
            pool = db.pool
        if not pool:
            raise RuntimeError("Database pool is not initialized.")
        return pool

    async def get_owner_dashboard(self) -> Dict[str, Any]:
        """
        Retrieves real-time dashboard snapshot from owner_dashboard view.
        """
        pool = await self._get_pool()
        query = "SELECT * FROM owner_dashboard LIMIT 1;"
        async with pool.acquire() as conn:
            row = await conn.fetchrow(query)
            return dict(row) if row else {}

    async def get_revenue_report(self) -> List[Dict[str, Any]]:
        """
        Retrieves daily revenue calculation from revenue_summary view.
        Enforces BR-023: payment_status = 'SUCCESS' AND refunded = false.
        """
        pool = await self._get_pool()
        query = "SELECT * FROM revenue_summary;"
        async with pool.acquire() as conn:
            rows = await conn.fetch(query)
            return [dict(row) for row in rows]

    async def get_cash_reconciliation_report(self) -> List[Dict[str, Any]]:
        """
        Retrieves cash handover discrepancy report from cash_reconciliation view.
        Enforces BP-011: Flags discrepancies (BALANCED, OVERAGE, SHORTFALL) for owner discretion without auto-resolving.
        """
        pool = await self._get_pool()
        query = "SELECT * FROM cash_reconciliation;"
        async with pool.acquire() as conn:
            rows = await conn.fetch(query)
            return [dict(row) for row in rows]

    async def get_rider_performance_report(self) -> List[Dict[str, Any]]:
        """
        Retrieves rider performance metrics from rider_performance view.
        """
        pool = await self._get_pool()
        query = "SELECT * FROM rider_performance;"
        async with pool.acquire() as conn:
            rows = await conn.fetch(query)
            return [dict(row) for row in rows]

    async def get_ride_history_report(self, limit: int = 50, offset: int = 0) -> List[Dict[str, Any]]:
        """
        Retrieves historical ride summary from ride_summary view.
        """
        pool = await self._get_pool()
        query = "SELECT * FROM ride_summary ORDER BY requested_at DESC LIMIT $1 OFFSET $2;"
        async with pool.acquire() as conn:
            rows = await conn.fetch(query, limit, offset)
            return [dict(row) for row in rows]

    async def list_places_historical(self, include_inactive: bool = True) -> List[Dict[str, Any]]:
        """
        Retrieves places including deactivated/soft-deleted places for historical reporting (BR-040).
        """
        pool = await self._get_pool()
        query = """
            SELECT id, name, latitude, longitude, place_type, origin, 
                   created_by, usage_count, active, created_at, updated_at
            FROM places
            WHERE (active = true OR $1 IS TRUE)
            ORDER BY name ASC;
        """
        async with pool.acquire() as conn:
            rows = await conn.fetch(query, include_inactive)
            return [dict(row) for row in rows]

    async def list_fare_templates_historical(self, include_inactive: bool = True) -> List[Dict[str, Any]]:
        """
        Retrieves fare templates including deactivated/soft-deleted templates for historical reporting (BR-040).
        """
        pool = await self._get_pool()
        query = """
            SELECT id, name, pickup_place_id, destination_place_id, fare,
                   estimated_distance, estimated_time, active, created_at, updated_at
            FROM fare_templates
            WHERE (active = true OR $1 IS TRUE)
            ORDER BY name ASC;
        """
        async with pool.acquire() as conn:
            rows = await conn.fetch(query, include_inactive)
            return [dict(row) for row in rows]

    async def create_cash_handover(
        self, rider_id: UUID, expected_cash: float, actual_cash: float, received_by: UUID, notes: Optional[str] = None
    ) -> dict:
        pool = await self._get_pool()
        query = """
            INSERT INTO cash_handovers (rider_id, expected_cash, actual_cash, received_by, notes)
            VALUES ($1, $2, $3, $4, $5)
            RETURNING id, rider_id, expected_cash, actual_cash, difference, received_by, notes, created_at;
        """
        async with pool.acquire() as conn:
            row = await conn.fetchrow(
                query,
                str(rider_id),
                expected_cash,
                actual_cash,
                str(received_by),
                notes
            )
            return dict(row) if row else {}

operations_repository = OperationsRepository()
