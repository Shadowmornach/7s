from decimal import Decimal
from uuid import UUID
from typing import Optional
from asyncpg import Pool
from app.db.connection import db
from app.schemas.rides import RideResponse, RideRequestPayload
from app.domain.exceptions import ResourceNotFoundError


class RideRepository:
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

    async def get_ride_version(self, ride_id: UUID) -> int:
        pool = await self._get_pool()
        async with pool.acquire() as conn:
            record = await conn.fetchrow(
                "SELECT version FROM rides WHERE id = $1",
                str(ride_id)
            )
            if not record:
                raise ResourceNotFoundError(f"Ride {ride_id} not found")
            return record["version"]

    async def get_ride_status(self, ride_id: UUID) -> str:
        pool = await self._get_pool()
        async with pool.acquire() as conn:
            record = await conn.fetchrow(
                "SELECT status FROM rides WHERE id = $1",
                str(ride_id)
            )
            if not record:
                raise ResourceNotFoundError(f"Ride {ride_id} not found")
            return record["status"]

    async def get_ride(self, ride_id: UUID) -> RideResponse:
        pool = await self._get_pool()
        async with pool.acquire() as conn:
            record = await conn.fetchrow(
                """
                SELECT r.id, r.passenger_id, r.rider_id, r.status, r.payment_status, r.version, r.created_at, r.updated_at,
                       s.id AS active_sos_id, s.severity AS active_sos_severity, s.status AS active_sos_status
                FROM rides r
                LEFT JOIN (
                    SELECT DISTINCT ON (ride_id) id, ride_id, severity, status
                    FROM sos_alerts
                    WHERE status = 'ACTIVE'
                    ORDER BY ride_id, created_at DESC
                ) s ON s.ride_id = r.id
                WHERE r.id = $1
                """,
                str(ride_id)
            )
            if not record:
                raise ResourceNotFoundError(f"Ride {ride_id} not found")
            return RideResponse(
                id=record["id"],
                passenger_id=record["passenger_id"],
                rider_id=record["rider_id"],
                status=record["status"],
                payment_status=record["payment_status"],
                version=record["version"],
                active_sos_id=record["active_sos_id"],
                active_sos_severity=record["active_sos_severity"],
                active_sos_status=record["active_sos_status"],
                created_at=record["created_at"],
                updated_at=record["updated_at"]
            )

    async def create_ride(self, passenger_id: UUID, payload: RideRequestPayload, booking_type: str) -> RideResponse:
        pool = await self._get_pool()
        async with pool.acquire() as conn:
            row = await conn.fetchrow(
                """
                WITH new_ride AS (
                    INSERT INTO rides (passenger_id, pickup_lat, pickup_lng, destination_lat, destination_lng, pickup_place_id, destination_place_id, booking_type, preferred_payment_method)
                    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
                    RETURNING id, passenger_id, rider_id, status, payment_status, version, created_at, updated_at
                ),
                new_event AS (
                    INSERT INTO ride_events (ride_id, ride_event_type, actor_id, metadata)
                    SELECT id, 'RIDE_REQUESTED', passenger_id, '{}'::jsonb
                    FROM new_ride
                )
                SELECT * FROM new_ride
                """,
                str(passenger_id),
                Decimal(str(payload.pickup_lat)),
                Decimal(str(payload.pickup_lng)),
                Decimal(str(payload.destination_lat)),
                Decimal(str(payload.destination_lng)),
                str(payload.pickup_place_id) if payload.pickup_place_id else None,
                str(payload.destination_place_id) if payload.destination_place_id else None,
                booking_type,
                payload.preferred_payment_method
            )
            return RideResponse(
                id=row["id"],
                passenger_id=row["passenger_id"],
                rider_id=row["rider_id"],
                status=row["status"],
                payment_status=row["payment_status"],
                version=row["version"],
                active_sos_id=None,
                active_sos_severity=None,
                active_sos_status=None,
                created_at=row["created_at"],
                updated_at=row["updated_at"]
            )

    async def get_all_rides(self, limit: int = 50, offset: int = 0) -> list[RideResponse]:
        pool = await self._get_pool()
        async with pool.acquire() as conn:
            records = await conn.fetch(
                """
                SELECT r.id, r.passenger_id, r.rider_id, r.status, r.payment_status, r.version, r.created_at, r.updated_at,
                       s.id AS active_sos_id, s.severity AS active_sos_severity, s.status AS active_sos_status
                FROM rides r
                LEFT JOIN (
                    SELECT DISTINCT ON (ride_id) id, ride_id, severity, status
                    FROM sos_alerts
                    WHERE status = 'ACTIVE'
                    ORDER BY ride_id, created_at DESC
                ) s ON s.ride_id = r.id
                ORDER BY r.created_at DESC
                LIMIT $1 OFFSET $2
                """,
                limit,
                offset,
            )
            return [
                RideResponse(
                    id=record["id"],
                    passenger_id=record["passenger_id"],
                    rider_id=record["rider_id"],
                    status=record["status"],
                    payment_status=record["payment_status"],
                    version=record["version"],
                    active_sos_id=record["active_sos_id"],
                    active_sos_severity=record["active_sos_severity"],
                    active_sos_status=record["active_sos_status"],
                    created_at=record["created_at"],
                    updated_at=record["updated_at"]
                )
                for record in records
            ]

    async def get_user_rides(self, user_id: UUID, role: str, limit: int = 50, offset: int = 0) -> list[RideResponse]:
        pool = await self._get_pool()
        async with pool.acquire() as conn:
            role_upper = role.upper() if role else ""
            if role_upper == "OWNER":
                query = """
                    SELECT r.id, r.passenger_id, r.rider_id, r.status, r.payment_status, r.version, r.created_at, r.updated_at,
                           s.id AS active_sos_id, s.severity AS active_sos_severity, s.status AS active_sos_status
                    FROM rides r
                    LEFT JOIN (
                        SELECT DISTINCT ON (ride_id) id, ride_id, severity, status
                        FROM sos_alerts
                        WHERE status = 'ACTIVE'
                        ORDER BY ride_id, created_at DESC
                    ) s ON s.ride_id = r.id
                    ORDER BY r.created_at DESC LIMIT $1 OFFSET $2
                """
                records = await conn.fetch(query, limit, offset)
            elif role_upper == "RIDER":
                query = """
                    SELECT r.id, r.passenger_id, r.rider_id, r.status, r.payment_status, r.version, r.created_at, r.updated_at,
                           s.id AS active_sos_id, s.severity AS active_sos_severity, s.status AS active_sos_status
                    FROM rides r
                    LEFT JOIN (
                        SELECT DISTINCT ON (ride_id) id, ride_id, severity, status
                        FROM sos_alerts
                        WHERE status = 'ACTIVE'
                        ORDER BY ride_id, created_at DESC
                    ) s ON s.ride_id = r.id
                    WHERE r.rider_id = $1 ORDER BY r.created_at DESC LIMIT $2 OFFSET $3
                """
                records = await conn.fetch(query, str(user_id), limit, offset)
            else:
                query = """
                    SELECT r.id, r.passenger_id, r.rider_id, r.status, r.payment_status, r.version, r.created_at, r.updated_at,
                           s.id AS active_sos_id, s.severity AS active_sos_severity, s.status AS active_sos_status
                    FROM rides r
                    LEFT JOIN (
                        SELECT DISTINCT ON (ride_id) id, ride_id, severity, status
                        FROM sos_alerts
                        WHERE status = 'ACTIVE'
                        ORDER BY ride_id, created_at DESC
                    ) s ON s.ride_id = r.id
                    WHERE r.passenger_id = $1 ORDER BY r.created_at DESC LIMIT $2 OFFSET $3
                """
                records = await conn.fetch(query, str(user_id), limit, offset)

            return [
                RideResponse(
                    id=record["id"],
                    passenger_id=record["passenger_id"],
                    rider_id=record["rider_id"],
                    status=record["status"],
                    payment_status=record["payment_status"],
                    version=record["version"],
                    active_sos_id=record["active_sos_id"],
                    active_sos_severity=record["active_sos_severity"],
                    active_sos_status=record["active_sos_status"],
                    created_at=record["created_at"],
                    updated_at=record["updated_at"]
                )
                for record in records
            ]

    async def get_rating_for_ride_by_user(self, ride_id: UUID, rated_by: UUID) -> Optional[dict]:
        pool = await self._get_pool()
        query = "SELECT id FROM ratings WHERE ride_id = $1 AND rated_by = $2"
        async with pool.acquire() as conn:
            row = await conn.fetchrow(query, str(ride_id), str(rated_by))
            return dict(row) if row else None

    async def insert_rating(self, ride_id: UUID, rated_by: UUID, rated_user: UUID, score: int, comment: Optional[str] = None) -> dict:
        pool = await self._get_pool()
        query = """
            INSERT INTO ratings (ride_id, rated_by, rated_user, score, comment)
            VALUES ($1, $2, $3, $4, $5)
            RETURNING id, ride_id, rated_by, rated_user, score, comment, created_at;
        """
        async with pool.acquire() as conn:
            row = await conn.fetchrow(query, str(ride_id), str(rated_by), str(rated_user), score, comment)
            return dict(row) if row else {}
