from uuid import UUID
from typing import Dict, Any, Optional
import asyncpg
from app.schemas.rides import UnifiedEventRequest, RideResponse, RideRequestPayload
from app.repositories.ride_repository import RideRepository
from app.repositories.event_repository import EventRepository
from app.domain.events import map_action_to_event
from app.domain.exceptions import ConcurrencyException, RuleViolationError, UnauthorizedError
from app.domain.ride_state_machine import validate_transition
from app.domain.pubsub import PubSubInterface

class RideService:
    def __init__(self, ride_repo: RideRepository, event_repo: EventRepository, pubsub_service: PubSubInterface):
        self.ride_repo = ride_repo
        self.event_repo = event_repo
        self.pubsub = pubsub_service


    async def handle_ride_event(self, ride_id: UUID, request: UnifiedEventRequest, actor_id: UUID, actor_role: str) -> RideResponse:
        # Enforce Authorization: Fails fast if user has no access to this ride
        ride = await self.get_ride(ride_id, actor_id, actor_role)
        
        event_type = map_action_to_event(request.action)
        
        current_status = await self.ride_repo.get_ride_status(ride_id)
        validate_transition(current_status, event_type)
        
        try:
            # Inject expected_version for atomic database validation
            metadata = request.metadata.copy() if request.metadata else {}
            metadata["expected_version"] = request.expected_version

            # We assume the DB triggers will enforce BR-029 (legal transitions), BR-041 (row-locking & version increment), etc.
            await self.event_repo.append_ride_event(
                ride_id=ride_id,
                event_type=event_type.value,
                actor_id=actor_id,
                metadata=metadata
            )
        except asyncpg.exceptions.CheckViolationError as e:
            raise RuleViolationError(f"Database constraint check failed: {str(e)}")
        except asyncpg.exceptions.RaiseError as e:
            if "Concurrency mismatch" in str(e):
                raise ConcurrencyException(str(e))
            # Trigger raised exception (illegal transition)
            raise RuleViolationError(f"Business rule violation in trigger: {str(e)}")

        updated_ride = await self.ride_repo.get_ride(ride_id)
        
        # Publish update to WebSockets
        await self.pubsub.publish(f"ride_{ride_id}", updated_ride.model_dump(mode='json'))
        
        return updated_ride

    async def create_ride(self, passenger_id: UUID, payload: RideRequestPayload) -> RideResponse:
        # BR-005: Booking Classification (Server-side computation placeholder)
        booking_type = "MANUAL"
        
        # Create initial record and initial event atomically via CTE
        ride = await self.ride_repo.create_ride(passenger_id, payload, booking_type)
            
        updated_ride = await self.ride_repo.get_ride(ride.id)
        
        # Publish update to WebSockets
        await self.pubsub.publish(f"ride_{ride.id}", updated_ride.model_dump(mode='json'))
        
        return updated_ride

    async def get_all_rides(self, limit: int = 50, offset: int = 0) -> list[RideResponse]:
        return await self.ride_repo.get_all_rides(limit=limit, offset=offset)

    async def get_user_rides(self, user_id: UUID, role: str, limit: int = 50, offset: int = 0) -> list[RideResponse]:
        return await self.ride_repo.get_user_rides(user_id=user_id, role=role, limit=limit, offset=offset)

    async def get_ride(self, ride_id: UUID, user_id: Optional[UUID] = None, role: str = "PASSENGER") -> RideResponse:
        ride = await self.ride_repo.get_ride(ride_id)
        if user_id is None:
            return ride
        if role and role.upper() == "OWNER":
            return ride
        if ride.passenger_id == user_id or ride.rider_id == user_id:
            return ride
        raise UnauthorizedError(f"User {user_id} is not authorized to access ride {ride_id}")

    async def update_rider_location(self, ride_id: UUID, rider_id: UUID, latitude: float, longitude: float) -> RideResponse:
        # Enforce Authorization: Check if user is the assigned rider
        ride = await self.get_ride(ride_id, rider_id, "RIDER")
        if ride.rider_id != rider_id:
            raise UnauthorizedError("Only the assigned rider can update the location coordinates.")
        
        # Append TELEMETRY_UPDATE event (does not change ride status)
        await self.event_repo.append_ride_event(
            ride_id=ride_id,
            event_type="TELEMETRY_UPDATE",
            actor_id=rider_id,
            lat=latitude,
            lng=longitude,
            metadata={"source": "telemetry"}
        )
        
        updated_ride = await self.ride_repo.get_ride(ride_id)
        
        # Publish update to WebSockets
        await self.pubsub.publish(f"ride_{ride_id}", updated_ride.model_dump(mode='json'))
        
        return updated_ride

    async def submit_ride_rating(self, ride_id: UUID, rated_by: UUID, rated_user: UUID, score: int, comment: Optional[str] = None) -> dict:
        from datetime import datetime, timezone, timedelta
        from app.domain.exceptions import RuleViolationError, ResourceNotFoundError

        ride = await self.ride_repo.get_ride(ride_id)
        if not ride:
            raise ResourceNotFoundError(f"Ride {ride_id} not found")

        if ride.status != "COMPLETED":
            raise RuleViolationError("Cannot rate a ride that is not completed")

        participants = {ride.passenger_id, ride.rider_id}
        if str(rated_by) not in [str(p) for p in participants] or str(rated_user) not in [str(p) for p in participants]:
            raise RuleViolationError("Only the ride passenger or driver can participate in rating")

        if str(rated_by) == str(rated_user):
            raise RuleViolationError("You cannot rate yourself")

        conn_pool = await self.ride_repo._get_pool()
        async with conn_pool.acquire() as conn:
            row = await conn.fetchrow("SELECT completed_at FROM rides WHERE id = $1", str(ride_id))
            completed_at = row["completed_at"] if row else None

        if not completed_at:
            raise RuleViolationError("Ride completion timestamp is missing")

        now = datetime.now(timezone.utc)
        if now - completed_at > timedelta(hours=24):
            raise RuleViolationError("Rating window has expired (24 hours past completion)")

        existing = await self.ride_repo.get_rating_for_ride_by_user(ride_id, rated_by)
        if existing:
            raise RuleViolationError("You have already rated this ride")

        return await self.ride_repo.insert_rating(
            ride_id=ride_id,
            rated_by=rated_by,
            rated_user=rated_user,
            score=score,
            comment=comment
        )
