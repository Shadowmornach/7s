from typing import Optional
from decimal import Decimal

from app.schemas.fares import RouteQuoteRequest, RouteQuoteResponse
from app.domain.exceptions import RuleViolationError

class FareService:
    def __init__(self, fare_template_repo, maps_service):
        self.fare_template_repo = fare_template_repo
        self.maps_service = maps_service

    async def get_route_quote(self, request: RouteQuoteRequest) -> RouteQuoteResponse:
        # 1. Enforce BR-018 Service Area
        await self.maps_service.validate_coordinates_in_service_area(
            request.pickup_lat, request.pickup_lng,
            request.destination_lat, request.destination_lng
        )

        # 2. Fare Template Lookup (BR-005, BR-006)
        if request.pickup_place_id and request.destination_place_id:
            template = await self.fare_template_repo.get_active_template_for_route(
                request.pickup_place_id, request.destination_place_id
            )
            if template:
                # 3. If template exists: Return stored fare, distance, ETA. NO routing call.
                return RouteQuoteResponse(
                    fare=template.fare,
                    estimated_distance_km=template.estimated_distance or Decimal("0.0"),
                    estimated_time_seconds=template.estimated_time or 0,
                    is_template_match=True
                )

        # 4. If template missing (or missing place IDs): Call OpenRouteService
        distance_km, eta_seconds = await self.maps_service.get_route(
            request.pickup_lat, request.pickup_lng,
            request.destination_lat, request.destination_lng
        )

        # 5. Return computed distance/ETA, but NO computed fare
        return RouteQuoteResponse(
            fare=None,
            estimated_distance_km=distance_km,
            estimated_time_seconds=eta_seconds,
            is_template_match=False
        )

    async def deactivate_template(self, template_id, owner_id) -> None:
        template = await self.fare_template_repo.get_template(template_id)
        if not template:
            from app.domain.exceptions import ResourceNotFoundError
            raise ResourceNotFoundError(f"Fare template {template_id} not found")
        await self.fare_template_repo.deactivate_template(template_id)
