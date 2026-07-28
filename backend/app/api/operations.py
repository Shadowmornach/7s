from fastapi import APIRouter, Depends, Query
from typing import List, Dict, Any, Optional

from app.schemas.auth import TokenPayload
from app.api.dependencies import require_role, get_operations_service
from app.services.operations_service import OperationsService

router = APIRouter(prefix="/operations", tags=["Operations & Reports"])

@router.get("/dashboard", response_model=Dict[str, Any])
async def get_owner_dashboard(
    current_user: TokenPayload = Depends(require_role(["OWNER"])),
    operations_service: OperationsService = Depends(get_operations_service)
):
    """
    Returns real-time owner dashboard snapshot.
    """
    return await operations_service.get_owner_dashboard()

@router.get("/reports/revenue", response_model=List[Dict[str, Any]])
async def get_revenue_report(
    current_user: TokenPayload = Depends(require_role(["OWNER"])),
    operations_service: OperationsService = Depends(get_operations_service)
):
    """
    Returns daily revenue calculations (BR-023: payment_status = 'SUCCESS' AND refunded = false).
    """
    return await operations_service.get_revenue_report()

@router.get("/reports/cash-handovers", response_model=List[Dict[str, Any]])
async def get_cash_reconciliation_report(
    current_user: TokenPayload = Depends(require_role(["OWNER"])),
    operations_service: OperationsService = Depends(get_operations_service)
):
    """
    Returns cash handover discrepancy report from cash_handovers table (BP-011).
    Flags discrepancies (BALANCED, OVERAGE, SHORTFALL) for owner discretion without auto-resolving.
    """
    return await operations_service.get_cash_reconciliation_report()

@router.get("/reports/rider-performance", response_model=List[Dict[str, Any]])
async def get_rider_performance_report(
    current_user: TokenPayload = Depends(require_role(["OWNER"])),
    operations_service: OperationsService = Depends(get_operations_service)
):
    """
    Returns rider performance metrics (completed rides, cancellations, ratings).
    """
    return await operations_service.get_rider_performance_report()

@router.get("/reports/ride-history", response_model=List[Dict[str, Any]])
async def get_ride_history_report(
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    current_user: TokenPayload = Depends(require_role(["OWNER"])),
    operations_service: OperationsService = Depends(get_operations_service)
):
    """
    Returns historical ride summary.
    """
    return await operations_service.get_ride_history_report(limit=limit, offset=offset)

@router.get("/reports/places", response_model=List[Dict[str, Any]])
async def get_places_report(
    include_inactive: bool = Query(default=True, description="Include soft-deleted/deactivated places for audit (BR-040)"),
    current_user: TokenPayload = Depends(require_role(["OWNER"])),
    operations_service: OperationsService = Depends(get_operations_service)
):
    """
    Returns places including soft-deleted/deactivated records for historical audit (BR-040).
    """
    return await operations_service.get_places_report(include_inactive=include_inactive)

@router.get("/reports/fare-templates", response_model=List[Dict[str, Any]])
async def get_fare_templates_report(
    include_inactive: bool = Query(default=True, description="Include soft-deleted/deactivated templates for audit (BR-040)"),
    current_user: TokenPayload = Depends(require_role(["OWNER"])),
    operations_service: OperationsService = Depends(get_operations_service)
):
    """
    Returns fare templates including soft-deleted/deactivated records for historical audit (BR-040).
    """
    return await operations_service.get_fare_templates_report(include_inactive=include_inactive)


from pydantic import BaseModel, Field
from uuid import UUID

class CashHandoverRequest(BaseModel):
    rider_id: UUID
    expected_cash: float
    actual_cash: float
    notes: Optional[str] = None

@router.post("/cash-handovers", status_code=201)
async def create_cash_handover(
    req: CashHandoverRequest,
    current_user: TokenPayload = Depends(require_role(["OWNER"])),
    operations_service: OperationsService = Depends(get_operations_service)
):
    """
    Creates an append-only cash handover record from a rider to an owner (BR-011).
    """
    owner_id = UUID(current_user.sub)
    return await operations_service.create_cash_handover(
        rider_id=req.rider_id,
        expected_cash=req.expected_cash,
        actual_cash=req.actual_cash,
        received_by=owner_id,
        notes=req.notes
    )
