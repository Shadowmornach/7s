from typing import List, Dict, Any, Optional
from app.repositories.operations_repository import OperationsRepository

class OperationsService:
    """
    Business service layer for Operations, Management, and Analytics.
    """

    def __init__(self, operations_repo: OperationsRepository):
        self.operations_repo = operations_repo

    async def get_owner_dashboard(self) -> Dict[str, Any]:
        return await self.operations_repo.get_owner_dashboard()

    async def get_revenue_report(self) -> List[Dict[str, Any]]:
        """
        Calculates daily revenue based on payment_status = 'SUCCESS' AND refunded = false (BR-023).
        """
        return await self.operations_repo.get_revenue_report()

    async def get_cash_reconciliation_report(self) -> List[Dict[str, Any]]:
        """
        Retrieves cash handover discrepancies from cash_handovers table (BP-011).
        Flags discrepancies (BALANCED, OVERAGE, SHORTFALL) for owner discretion without auto-resolving.
        """
        return await self.operations_repo.get_cash_reconciliation_report()

    async def get_rider_performance_report(self) -> List[Dict[str, Any]]:
        return await self.operations_repo.get_rider_performance_report()

    async def get_ride_history_report(self, limit: int = 50, offset: int = 0) -> List[Dict[str, Any]]:
        return await self.operations_repo.get_ride_history_report(limit=limit, offset=offset)

    async def get_places_report(self, include_inactive: bool = True) -> List[Dict[str, Any]]:
        """
        Retrieves places including deactivated/soft-deleted places for historical reporting (BR-040).
        """
        return await self.operations_repo.list_places_historical(include_inactive=include_inactive)

    async def get_fare_templates_report(self, include_inactive: bool = True) -> List[Dict[str, Any]]:
        """
        Retrieves fare templates including deactivated/soft-deleted templates for historical reporting (BR-040).
        """
        return await self.operations_repo.list_fare_templates_historical(include_inactive=include_inactive)

    async def create_cash_handover(
        self, rider_id: Any, expected_cash: float, actual_cash: float, received_by: Any, notes: Optional[str] = None
    ) -> Dict[str, Any]:
        return await self.operations_repo.create_cash_handover(
            rider_id=rider_id,
            expected_cash=expected_cash,
            actual_cash=actual_cash,
            received_by=received_by,
            notes=notes
        )
