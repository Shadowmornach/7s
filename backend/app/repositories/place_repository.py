from typing import List, Optional
from uuid import UUID
from datetime import datetime
from decimal import Decimal

from app.schemas.places import PlaceCreate, PlaceUpdate, PlaceResponse, PlaceType
from app.domain.exceptions import ResourceNotFoundError

class PlaceRepository:
    def __init__(self, pool):
        self.pool = pool

    async def get_place(self, place_id: UUID) -> Optional[PlaceResponse]:
        query = """
            SELECT id, name, latitude, longitude, place_type, origin, 
                   created_by, usage_count, active, created_at, updated_at
            FROM places
            WHERE id = $1
        """
        async with self.pool.acquire() as conn:
            row = await conn.fetchrow(query, place_id)
            if not row:
                return None
            return PlaceResponse(**dict(row))

    async def create_place(self, creator_id: UUID, payload: PlaceCreate) -> PlaceResponse:
        query = """
            INSERT INTO places (name, latitude, longitude, place_type, origin, created_by)
            VALUES ($1, $2, $3, $4, $5, $6)
            RETURNING id, name, latitude, longitude, place_type, origin, 
                      created_by, usage_count, active, created_at, updated_at
        """
        async with self.pool.acquire() as conn:
            row = await conn.fetchrow(
                query,
                payload.name,
                payload.latitude,
                payload.longitude,
                payload.place_type.value,
                payload.origin.value,
                creator_id
            )
            return PlaceResponse(**dict(row))

    async def update_place(self, place_id: UUID, payload: PlaceUpdate) -> PlaceResponse:
        updates = []
        values = []
        
        if payload.name is not None:
            values.append(payload.name)
            updates.append(f"name = ${len(values)}")
            
        if payload.active is not None:
            values.append(payload.active)
            updates.append(f"active = ${len(values)}")
            
        if not updates:
            place = await self.get_place(place_id)
            if not place:
                raise ResourceNotFoundError(f"Place {place_id} not found")
            return place
            
        updates.append("updated_at = now()")
        values.append(place_id)
        
        query = f"""
            UPDATE places
            SET {', '.join(updates)}
            WHERE id = ${len(values)}
            RETURNING id, name, latitude, longitude, place_type, origin, 
                      created_by, usage_count, active, created_at, updated_at
        """
        
        async with self.pool.acquire() as conn:
            row = await conn.fetchrow(query, *values)
            if not row:
                raise ResourceNotFoundError(f"Place {place_id} not found")
            return PlaceResponse(**dict(row))

    async def list_places(self, active_only: bool = True, place_types: Optional[List[PlaceType]] = None) -> List[PlaceResponse]:
        query = """
            SELECT id, name, latitude, longitude, place_type, origin, 
                   created_by, usage_count, active, created_at, updated_at
            FROM places
            WHERE (active = $1 OR $1 IS FALSE)
        """
        params = [active_only]
        
        if place_types:
            type_strs = [pt.value for pt in place_types]
            query += f" AND place_type = ANY(${len(params) + 1})"
            params.append(type_strs)
            
        query += " ORDER BY name ASC"
        
        async with self.pool.acquire() as conn:
            rows = await conn.fetch(query, *params)
            return [PlaceResponse(**dict(row)) for row in rows]
