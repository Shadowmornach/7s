from typing import List, Optional
from uuid import UUID

from app.schemas.fares import FareTemplateResponse
from app.domain.exceptions import ResourceNotFoundError

class FareTemplateRepository:
    def __init__(self, pool):
        self.pool = pool

    async def get_active_template_for_route(self, from_place_id: UUID, to_place_id: UUID) -> Optional[FareTemplateResponse]:
        query = """
            SELECT id, from_place_id, to_place_id, fare, estimated_distance, 
                   estimated_time, active, notes, created_at, last_updated
            FROM fare_templates
            WHERE from_place_id = $1 AND to_place_id = $2 AND active = true
            LIMIT 1
        """
        async with self.pool.acquire() as conn:
            row = await conn.fetchrow(query, from_place_id, to_place_id)
            if not row:
                return None
            return FareTemplateResponse(**dict(row))

    async def get_template(self, template_id: UUID) -> Optional[FareTemplateResponse]:
        query = """
            SELECT id, from_place_id, to_place_id, fare, estimated_distance, 
                   estimated_time, active, notes, created_at, last_updated
            FROM fare_templates
            WHERE id = $1
        """
        async with self.pool.acquire() as conn:
            row = await conn.fetchrow(query, template_id)
            if not row:
                return None
            return FareTemplateResponse(**dict(row))

    async def deactivate_template(self, template_id: UUID) -> None:
        query = """
            UPDATE fare_templates
            SET active = false
            WHERE id = $1
        """
        async with self.pool.acquire() as conn:
            await conn.execute(query, template_id)
