from fastapi import APIRouter, Depends, Query, status
from typing import List, Optional
from uuid import UUID

from app.api.dependencies import get_current_user, get_place_service
from app.schemas.places import PlaceCreate, PlaceUpdate, PlaceResponse, PlaceType
from app.schemas.auth import TokenPayload
from app.services.place_service import PlaceService
from app.domain.exceptions import DomainException
from fastapi import HTTPException

router = APIRouter()

@router.post("/", response_model=PlaceResponse, status_code=status.HTTP_201_CREATED)
async def create_place(
    payload: PlaceCreate,
    current_user: TokenPayload = Depends(get_current_user),
    place_service: PlaceService = Depends(get_place_service)
):
    try:
        return await place_service.create_place(UUID(current_user.sub), current_user.role, payload)
    except DomainException as e:
        status_code = status.HTTP_403_FORBIDDEN if e.code == "UNAUTHORIZED" else status.HTTP_400_BAD_REQUEST
        raise HTTPException(status_code=status_code, detail={"error_code": e.code, "message": str(e)})

@router.get("/", response_model=List[PlaceResponse])
async def list_places(
    active_only: bool = Query(True),
    place_types: Optional[List[PlaceType]] = Query(None),
    current_user: TokenPayload = Depends(get_current_user),
    place_service: PlaceService = Depends(get_place_service)
):
    try:
        return await place_service.list_places(active_only, place_types, UUID(current_user.sub), current_user.role)
    except DomainException as e:
        status_code = status.HTTP_403_FORBIDDEN if e.code == "UNAUTHORIZED" else status.HTTP_400_BAD_REQUEST
        raise HTTPException(status_code=status_code, detail={"error_code": e.code, "message": str(e)})

@router.get("/{place_id}", response_model=PlaceResponse)
async def get_place(
    place_id: UUID,
    current_user: TokenPayload = Depends(get_current_user),
    place_service: PlaceService = Depends(get_place_service)
):
    try:
        return await place_service.get_place(place_id, UUID(current_user.sub), current_user.role)
    except DomainException as e:
        status_code = status.HTTP_403_FORBIDDEN if e.code == "UNAUTHORIZED" else status.HTTP_400_BAD_REQUEST
        raise HTTPException(status_code=status_code, detail={"error_code": e.code, "message": str(e)})

@router.patch("/{place_id}", response_model=PlaceResponse)
async def update_place(
    place_id: UUID,
    payload: PlaceUpdate,
    current_user: TokenPayload = Depends(get_current_user),
    place_service: PlaceService = Depends(get_place_service)
):
    try:
        return await place_service.update_place(place_id, UUID(current_user.sub), current_user.role, payload)
    except DomainException as e:
        status_code = status.HTTP_403_FORBIDDEN if e.code == "UNAUTHORIZED" else status.HTTP_400_BAD_REQUEST
        raise HTTPException(status_code=status_code, detail={"error_code": e.code, "message": str(e)})

@router.delete("/{place_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_place(
    place_id: UUID,
    current_user: TokenPayload = Depends(get_current_user),
    place_service: PlaceService = Depends(get_place_service)
):
    try:
        await place_service.delete_place(place_id, UUID(current_user.sub), current_user.role)
    except DomainException as e:
        status_code = status.HTTP_403_FORBIDDEN if e.code == "UNAUTHORIZED" else status.HTTP_400_BAD_REQUEST
        raise HTTPException(status_code=status_code, detail={"error_code": e.code, "message": str(e)})
