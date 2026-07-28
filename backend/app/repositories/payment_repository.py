import json
from decimal import Decimal
from typing import List, Optional, Dict, Any
from uuid import UUID
import asyncpg
from app.db.connection import db
from app.schemas.payments import PaymentEventCreate

class PaymentRepository:
    """
    Persistence layer for Payment Events.
    Strictly SQL. No business logic, no orchestration, no external APIs.
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

    async def insert_payment_event(self, event: PaymentEventCreate) -> Dict[str, Any]:
        """
        Appends a new payment event to the immutable event log.
        This is the ONLY way payment state changes are requested.
        """
        pool = await self._get_pool()

        # Convert float to Decimal for PostgreSQL DECIMAL(10, 2) compatibility with asyncpg
        amount_decimal: Optional[Decimal] = Decimal(str(event.amount)) if event.amount is not None else None

        # Convert dictionaries to JSON strings for asyncpg jsonb casting
        raw_callback_json = json.dumps(event.raw_callback) if event.raw_callback is not None else None
        metadata_json = json.dumps(event.metadata) if event.metadata is not None else '{}'

        query = """
            INSERT INTO payment_events (
                ride_id, 
                payment_event_type, 
                mpesa_receipt, 
                phone_number_used, 
                amount, 
                raw_callback, 
                metadata
            )
            VALUES ($1, $2, $3, $4, $5, $6::jsonb, $7::jsonb)
            RETURNING *;
        """
        async with pool.acquire() as conn:
            row = await conn.fetchrow(
                query,
                event.ride_id,
                event.payment_event_type,
                event.mpesa_receipt,
                event.phone_number_used,
                amount_decimal,
                raw_callback_json,
                metadata_json
            )
            return dict(row)

    async def get_payment_by_mpesa_receipt(self, mpesa_receipt: str) -> Optional[Dict[str, Any]]:
        """
        Look up an event by the canonical M-PESA receipt string.
        """
        pool = await self._get_pool()
        query = """
            SELECT * 
            FROM payment_events 
            WHERE mpesa_receipt = $1
            ORDER BY sequence_number DESC
            LIMIT 1;
        """
        async with pool.acquire() as conn:
            row = await conn.fetchrow(query, mpesa_receipt)
            return dict(row) if row else None

    async def get_payment_by_checkout_request_id(self, checkout_request_id: str) -> Optional[Dict[str, Any]]:
        """
        Look up an event using CheckoutRequestID embedded inside the metadata JSONB column.
        """
        pool = await self._get_pool()
        query = """
            SELECT * 
            FROM payment_events 
            WHERE metadata->>'CheckoutRequestID' = $1
            ORDER BY sequence_number DESC
            LIMIT 1;
        """
        async with pool.acquire() as conn:
            row = await conn.fetchrow(query, checkout_request_id)
            return dict(row) if row else None

    async def get_payment_history(self, ride_id: UUID) -> List[Dict[str, Any]]:
        """
        Retrieve all payment events for a given ride, ordered monotonically by sequence.
        """
        pool = await self._get_pool()
        query = """
            SELECT * 
            FROM payment_events 
            WHERE ride_id = $1
            ORDER BY sequence_number ASC;
        """
        async with pool.acquire() as conn:
            rows = await conn.fetch(query, ride_id)
            return [dict(row) for row in rows]

    async def payment_exists(self, ride_id: UUID) -> bool:
        """
        Check if any payment events have been logged for this ride.
        Does NOT infer payment success.
        """
        pool = await self._get_pool()
        query = """
            SELECT 1 
            FROM payment_events 
            WHERE ride_id = $1 
            LIMIT 1;
        """
        async with pool.acquire() as conn:
            row = await conn.fetchrow(query, ride_id)
            return bool(row)

    async def get_default_active_payment_account(self) -> Optional[Dict[str, Any]]:
        """
        Retrieves the default active payment account configured by the owner (BR-010).
        If none exists, MPESA payment options must not be offered.
        """
        pool = await self._get_pool()
        query = """
            SELECT id, provider, display_name, till_paybill_or_number, is_default, status
            FROM payment_accounts
            WHERE is_default = true AND status = 'active'
            LIMIT 1;
        """
        async with pool.acquire() as conn:
            row = await conn.fetchrow(query)
            return dict(row) if row else None

    async def get_latest_payment_attempt(self, ride_id: UUID) -> Optional[Dict[str, Any]]:
        """
        Retrieves the most recent PAYMENT_ATTEMPT event for a ride.
        Used for STK status query checks and timeout fallbacks.
        """
        pool = await self._get_pool()
        query = """
            SELECT *
            FROM payment_events
            WHERE ride_id = $1 AND payment_event_type = 'PAYMENT_ATTEMPT'
            ORDER BY sequence_number DESC
            LIMIT 1;
        """
        async with pool.acquire() as conn:
            row = await conn.fetchrow(query, ride_id)
            return dict(row) if row else None

    async def get_pending_stk_payments(self, timeout_seconds: int = 90) -> List[Dict[str, Any]]:
        """
        Queries all rides whose payment_status = 'PENDING' and whose latest PAYMENT_ATTEMPT 
        was created more than timeout_seconds ago (BR-010 reconciliation).
        """
        pool = await self._get_pool()
        query = """
            SELECT DISTINCT ON (r.id) 
                   r.id AS ride_id, 
                   pe.metadata->>'CheckoutRequestID' AS checkout_request_id,
                   pe.amount,
                   pe.phone_number_used,
                   pe.created_at AS attempt_time
            FROM rides r
            JOIN payment_events pe ON r.id = pe.ride_id
            WHERE r.payment_status = 'PENDING'
              AND pe.payment_event_type = 'PAYMENT_ATTEMPT'
              AND pe.created_at <= (now() - ($1 || ' seconds')::INTERVAL)
            ORDER BY r.id, pe.sequence_number DESC;
        """
        async with pool.acquire() as conn:
            rows = await conn.fetch(query, timeout_seconds)
            return [dict(row) for row in rows]

payment_repository = PaymentRepository()
