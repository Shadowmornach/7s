from uuid import UUID
from typing import List, Optional

from app.schemas.places import PlaceCreate, PlaceUpdate, PlaceResponse, PlaceType
from app.domain.exceptions import UnauthorizedError

class PlaceService:
    def __init__(self, place_repo, maps_service):
        self.place_repo = place_repo
        self.maps_service = maps_service

    async def create_place(self, creator_id: UUID, role: str, payload: PlaceCreate) -> PlaceResponse:
        # Enforce BR-018: Place coordinates must be inside the service radius
        await self.maps_service.validate_coordinates_in_service_area(
            payload.latitude, payload.longitude,
            payload.latitude, payload.longitude # Validate the same point twice just to reuse method
        )

        # Enforce BR-014: Only owner can create SYSTEM and OWNER places
        if payload.place_type in (PlaceType.SYSTEM, PlaceType.OWNER):
            if role.upper() != "OWNER":
                raise UnauthorizedError(f"Only owners can create {payload.place_type.value} places")
        
        # USER places are allowed for everyone, created_by handles the RLS logic
        return await self.place_repo.create_place(creator_id, payload)

    async def update_place(self, place_id: UUID, actor_id: UUID, role: str, payload: PlaceUpdate) -> PlaceResponse:
        place = await self.place_repo.get_place(place_id)
        if not place:
            raise UnauthorizedError("Place not found") # Or ResourceNotFoundError, but typically we blur them for security

        # Enforce BR-014 updates:
        if place.place_type in (PlaceType.SYSTEM, PlaceType.OWNER):
            if role.upper() != "OWNER":
                raise UnauthorizedError(f"Only owners can edit {place.place_type.value} places")
        else:
            if place.created_by != actor_id:
                raise UnauthorizedError("Cannot edit another user's place")

        return await self.place_repo.update_place(place_id, payload)

    async def get_place(self, place_id: UUID, actor_id: UUID, role: str) -> PlaceResponse:
        place = await self.place_repo.get_place(place_id)
        if not place:
            raise UnauthorizedError("Place not found")
            
        if place.place_type == PlaceType.USER and place.created_by != actor_id and role.upper() != "OWNER":
            raise UnauthorizedError("Place not found")

        return place

    async def list_places(self, active_only: bool, place_types: Optional[List[PlaceType]], actor_id: UUID, role: str) -> List[PlaceResponse]:
        # The repository fetches all matching places.
        # We must filter USER places in Python if RLS isn't actively doing it in this context (e.g. if we use a service role).
        # Actually, if we use a normal pool connection and we aren't using Row Level Security directly via set_config
        # (which we aren't, standard FastAPI backend connects as a privileged user in this codebase),
        # we MUST enforce RLS in Python.
        
        places = await self.place_repo.list_places(active_only, place_types)
        
        filtered = []
        for p in places:
            if p.place_type in (PlaceType.SYSTEM, PlaceType.OWNER):
                filtered.append(p)
            elif p.place_type == PlaceType.USER:
                # USER place visibility (BR-014)
                if p.created_by == actor_id or role.upper() == "OWNER":
                    filtered.append(p)
                    
        return filtered

    async def delete_place(self, place_id: UUID, actor_id: UUID, role: str):
        # Soft delete (BR-024, BR-014)
        await self.update_place(place_id, actor_id, role, PlaceUpdate(active=False))
