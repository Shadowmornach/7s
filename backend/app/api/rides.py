from fastapi import APIRouter, Depends, Header, HTTPException, Query, status
from uuid import UUID
from app.schemas.rides import UnifiedEventRequest, RideResponse, RideRequestPayload, CashHandoverRequest, RatingRequest, RiderLocationPayload
from app.services.ride_service import RideService
from app.domain.exceptions import DomainException
from app.api.dependencies import get_ride_service, get_current_user, require_role
from app.schemas.auth import TokenPayload

router = APIRouter(prefix="/rides", tags=["Rides"])


@router.post("/request", response_model=RideResponse)
async def request_ride(
    payload: RideRequestPayload,
    current_user: TokenPayload = Depends(get_current_user),
    ride_service: RideService = Depends(get_ride_service)
):
    try:
        user_id = UUID(current_user.sub)
        return await ride_service.create_ride(user_id, payload)
    except DomainException as e:
        raise HTTPException(status_code=400, detail={"error_code": e.code, "message": str(e)})

@router.post("/{ride_id}/events", response_model=RideResponse)
async def handle_ride_event(
    ride_id: UUID,
    request: UnifiedEventRequest,
    current_user: TokenPayload = Depends(get_current_user),
    ride_service: RideService = Depends(get_ride_service)
):
    try:
        user_id = UUID(current_user.sub)
        return await ride_service.handle_ride_event(ride_id, request, user_id, current_user.role)
    except DomainException as e:
        if e.code == "UNAUTHORIZED":
            status_code = status.HTTP_403_FORBIDDEN
        elif e.code == "CONCURRENCY_ERROR":
            status_code = status.HTTP_409_CONFLICT
        else:
            status_code = status.HTTP_400_BAD_REQUEST
        raise HTTPException(status_code=status_code, detail={"error_code": e.code, "message": str(e)})

@router.get("", response_model=list[RideResponse])
async def get_rides(
    current_user: TokenPayload = Depends(get_current_user),
    ride_service: RideService = Depends(get_ride_service),
    limit: int = Query(default=50, ge=1, le=200, description="Page size (max 200)"),
    offset: int = Query(default=0, ge=0, description="Number of records to skip"),
):
    try:
        user_id = UUID(current_user.sub)
        return await ride_service.get_user_rides(user_id=user_id, role=current_user.role, limit=limit, offset=offset)
    except DomainException as e:
        status_code = status.HTTP_403_FORBIDDEN if e.code == "UNAUTHORIZED" else status.HTTP_400_BAD_REQUEST
        raise HTTPException(status_code=status_code, detail={"error_code": e.code, "message": str(e)})

@router.get("/{ride_id}", response_model=RideResponse)
async def get_ride(
    ride_id: UUID,
    current_user: TokenPayload = Depends(get_current_user),
    ride_service: RideService = Depends(get_ride_service)
):
    try:
        user_id = UUID(current_user.sub)
        return await ride_service.get_ride(ride_id=ride_id, user_id=user_id, role=current_user.role)
    except DomainException as e:
        if e.code == "NOT_FOUND":
            status_code = status.HTTP_404_NOT_FOUND
        elif e.code == "UNAUTHORIZED":
            status_code = status.HTTP_403_FORBIDDEN
        else:
            status_code = status.HTTP_400_BAD_REQUEST
        raise HTTPException(status_code=status_code, detail={"error_code": e.code, "message": str(e)})

@router.post("/{ride_id}/location", response_model=RideResponse)
async def update_rider_location(
    ride_id: UUID,
    payload: RiderLocationPayload,
    current_user: TokenPayload = Depends(require_role(["RIDER"])),
    ride_service: RideService = Depends(get_ride_service)
):
    """
    Rider updates their current location coordinates during an active ride.
    """
    try:
        user_id = UUID(current_user.sub)
        return await ride_service.update_rider_location(
            ride_id=ride_id,
            rider_id=user_id,
            latitude=payload.latitude,
            longitude=payload.longitude
        )
    except DomainException as e:
        status_code = status.HTTP_403_FORBIDDEN if e.code == "UNAUTHORIZED" else status.HTTP_400_BAD_REQUEST
        raise HTTPException(status_code=status_code, detail={"error_code": e.code, "message": str(e)})


@router.post("/{ride_id}/rate", status_code=status.HTTP_201_CREATED)
async def submit_ride_rating(
    ride_id: UUID,
    payload: RatingRequest,
    current_user: TokenPayload = Depends(get_current_user),
    ride_service: RideService = Depends(get_ride_service)
):
    """
    Submits a rating for a completed ride within 24 hours (BR-033).
    """
    try:
        user_id = UUID(current_user.sub)
        return await ride_service.submit_ride_rating(
            ride_id=ride_id,
            rated_by=user_id,
            rated_user=payload.rated_user,
            score=payload.score,
            comment=payload.comment
        )
    except DomainException as e:
        status_code = status.HTTP_403_FORBIDDEN if e.code == "UNAUTHORIZED" else status.HTTP_400_BAD_REQUEST
        raise HTTPException(status_code=status_code, detail={"error_code": e.code, "message": str(e)})



