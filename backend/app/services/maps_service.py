import math
import httpx
from decimal import Decimal
from typing import Tuple, Dict, Any, Optional
import logging

from app.core.config import settings
from app.domain.exceptions import RuleViolationError

logger = logging.getLogger("7s.maps")

class MapsService:
    def __init__(self, config_repo):
        self.config_repo = config_repo

    def _haversine(self, lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        # Earth radius in kilometers
        R = 6371.0
        
        dlat = math.radians(lat2 - lat1)
        dlon = math.radians(lon2 - lon1)
        
        a = math.sin(dlat / 2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon / 2)**2
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
        
        return R * c

    async def is_within_service_radius(self, lat: Decimal, lng: Decimal) -> bool:
        # Fetch configuration (with defaults per Doc 6)
        center_lat_val = await self.config_repo.get_config_value("service_center_lat")
        center_lng_val = await self.config_repo.get_config_value("service_center_lng")
        radius_km_val = await self.config_repo.get_config_value("service_radius_km")

        center_lat = float(center_lat_val) if center_lat_val is not None else -3.3962
        center_lng = float(center_lng_val) if center_lng_val is not None else 38.5561
        radius_km = float(radius_km_val) if radius_km_val is not None else 20.0

        distance = self._haversine(float(lat), float(lng), center_lat, center_lng)
        return distance <= radius_km

    async def validate_coordinates_in_service_area(self, pickup_lat: Decimal, pickup_lng: Decimal, dest_lat: Decimal, dest_lng: Decimal):
        # BR-018: Pickup and destination must both fall inside the radius, checked server-side
        is_pickup_valid = await self.is_within_service_radius(pickup_lat, pickup_lng)
        if not is_pickup_valid:
            raise RuleViolationError("Pickup location is outside the service area.")

        is_dest_valid = await self.is_within_service_radius(dest_lat, dest_lng)
        if not is_dest_valid:
            raise RuleViolationError("Destination is outside the service area.")

    async def get_route(self, pickup_lat: Decimal, pickup_lng: Decimal, dest_lat: Decimal, dest_lng: Decimal) -> Tuple[Decimal, int]:
        """
        Calls OpenRouteService to calculate distance and ETA.
        Returns:
            Tuple[Decimal, int]: (distance_in_km, eta_in_seconds)
        """
        api_key = settings.ORS_API_KEY.get_secret_value() if settings.ORS_API_KEY else None
        if not api_key:
            # For local dev / testing without API key, use haversine + generic speed
            logger.warning("ORS_API_KEY not configured. Falling back to straight-line distance.")
            distance_km = Decimal(str(round(self._haversine(float(pickup_lat), float(pickup_lng), float(dest_lat), float(dest_lng)), 2)))
            # Assume 30 km/h average speed in town
            eta_seconds = int((float(distance_km) / 30.0) * 3600)
            return distance_km, eta_seconds

        # ORS expects coordinates as [longitude, latitude]
        url = "https://api.openrouteservice.org/v2/directions/driving-car"
        headers = {
            "Authorization": api_key,
            "Accept": "application/json, application/geo+json, application/gpx+xml, img/png; charset=utf-8"
        }
        params = {
            "start": f"{float(pickup_lng)},{float(pickup_lat)}",
            "end": f"{float(dest_lng)},{float(dest_lat)}"
        }

        async with httpx.AsyncClient() as client:
            try:
                response = await client.get(url, params=params, headers=headers, timeout=10.0)
                response.raise_for_status()
                data = response.json()
                
                # Extract summary
                summary = data["features"][0]["properties"]["summary"]
                distance_meters = summary["distance"]
                duration_seconds = summary["duration"]
                
                distance_km = Decimal(str(round(distance_meters / 1000.0, 2)))
                return distance_km, int(duration_seconds)
            except Exception as e:
                logger.error(f"ORS API request failed: {e}")
                raise RuleViolationError("Failed to calculate route. Please try again.")
