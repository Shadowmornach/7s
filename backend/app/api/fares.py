from fastapi import APIRouter, Depends, Query, status
from typing import List, Optional
from uuid import UUID
from decimal import Decimal

from app.api.dependencies import get_current_user, get_fare_service
from app.schemas.fares import RouteQuoteRequest, RouteQuoteResponse
from app.schemas.auth import TokenPayload
from app.services.fare_service import FareService
from app.domain.exceptions import DomainException
from fastapi import HTTPException

router = APIRouter()

@router.post("/quote", response_model=RouteQuoteResponse)
async def get_route_quote(
    request: RouteQuoteRequest,
    current_user: TokenPayload = Depends(get_current_user),
    fare_service: FareService = Depends(get_fare_service)
):
    """
    Returns a fare quote (if a template matches) and routing distance/ETA.
    Per BR-006, the system never automatically calculates a fare price unless it matches an owner-created template.
    """
    try:
        return await fare_service.get_route_quote(request)
    except DomainException as e:
        status_code = status.HTTP_403_FORBIDDEN if e.code == "UNAUTHORIZED" else status.HTTP_400_BAD_REQUEST
        raise HTTPException(status_code=status_code, detail={"error_code": e.code, "message": str(e)})


@router.delete("/{template_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_fare_template(
    template_id: UUID,
    current_user: TokenPayload = Depends(get_current_user),
    fare_service: FareService = Depends(get_fare_service)
):
    """
    Deactivates (soft-deletes) a fare template. Requires Owner role (BR-040).
    """
    if current_user.role.upper() != "OWNER":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only owners can deactivate fare templates"
        )
    try:
        await fare_service.deactivate_template(template_id, UUID(current_user.sub))
    except DomainException as e:
        status_code = status.HTTP_403_FORBIDDEN if e.code == "UNAUTHORIZED" else status.HTTP_400_BAD_REQUEST
        raise HTTPException(status_code=status_code, detail={"error_code": e.code, "message": str(e)})
