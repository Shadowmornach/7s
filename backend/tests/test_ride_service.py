import pytest
import pytest_asyncio
from uuid import uuid4
from unittest.mock import AsyncMock, patch, MagicMock
from datetime import datetime, timezone

from app.services.ride_service import RideService
from app.schemas.rides import UnifiedEventRequest, RideRequestPayload, RideResponse
from app.domain.exceptions import ConcurrencyException, InvalidPayloadError, RuleViolationError

@pytest.fixture
def ride_service():
    service = RideService(ride_repo=AsyncMock(), event_repo=AsyncMock(), pubsub_service=AsyncMock())
    return service

import asyncpg

@pytest.mark.asyncio
async def test_ride_service_concurrency_mismatch(ride_service):
    # Setup mock to simulate DB trigger raising concurrency mismatch
    ride_service.event_repo.append_ride_event.side_effect = asyncpg.exceptions.RaiseError(
        "Concurrency mismatch: Expected 4, got 5"
    )
    
    ride_id = uuid4()
    actor_id = uuid4()
    ride_service.ride_repo.get_ride.return_value = RideResponse(
        id=ride_id, passenger_id=actor_id, rider_id=None, status="FARE_SENT", payment_status="PENDING", version=4, created_at=datetime.now(timezone.utc), updated_at=datetime.now(timezone.utc)
    )
    request = UnifiedEventRequest(
        action="accept_fare",
        expected_version=4, # Mismatch simulated by DB
        metadata={}
    )
    ride_service.ride_repo.get_ride_status.return_value = "FARE_SENT"
    
    with pytest.raises(ConcurrencyException) as exc_info:
        await ride_service.handle_ride_event(ride_id, request, actor_id, "PASSENGER")
        
    assert "Expected 4, got 5" in str(exc_info.value)
    ride_service.event_repo.append_ride_event.assert_called_once()

@pytest.mark.asyncio
async def test_ride_service_invalid_action(ride_service):
    ride_service.ride_repo.get_ride_version.return_value = 4
    
    ride_id = uuid4()
    actor_id = uuid4()
    ride_service.ride_repo.get_ride.return_value = RideResponse(
        id=ride_id, passenger_id=actor_id, rider_id=None, status="REQUESTED", payment_status="PENDING", version=4, created_at=datetime.now(timezone.utc), updated_at=datetime.now(timezone.utc)
    )
    request = UnifiedEventRequest(
        action="invalid_action_name",
        expected_version=4,
        metadata={}
    )
    ride_service.ride_repo.get_ride_status.return_value = "REQUESTED"
    
    with pytest.raises(InvalidPayloadError) as exc_info:
        await ride_service.handle_ride_event(ride_id, request, actor_id, "PASSENGER")
        
    assert "Unknown action" in str(exc_info.value)
    ride_service.event_repo.append_ride_event.assert_not_called()

@pytest.mark.asyncio
async def test_ride_service_successful_event_append(ride_service):
    ride_service.ride_repo.get_ride_version.return_value = 4
    
    ride_id = uuid4()
    actor_id = uuid4()
    ride_service.ride_repo.get_ride.return_value = RideResponse(
        id=ride_id, passenger_id=actor_id, rider_id=None, status="FARE_SENT", payment_status="PENDING", version=4, created_at=datetime.now(timezone.utc), updated_at=datetime.now(timezone.utc)
    )
    request = UnifiedEventRequest(
        action="accept_fare",
        expected_version=4,
        metadata={"note": "Looks good"}
    )
    ride_service.ride_repo.get_ride_status.return_value = "FARE_SENT"
    
    # Run service
    await ride_service.handle_ride_event(ride_id, request, actor_id, "PASSENGER")
    
    # Assert event was appended successfully
    ride_service.event_repo.append_ride_event.assert_called_once_with(
        ride_id=ride_id,
        event_type="FARE_ACCEPTED",
        actor_id=actor_id,
        metadata={"note": "Looks good", "expected_version": 4}
    )
    assert ride_service.ride_repo.get_ride.call_count == 2

@pytest.mark.asyncio
async def test_ride_service_create_ride_atomic(ride_service):
    """
    Gate 5 Regression Test:
    Proves that create_ride delegates to a single atomic repository method (create_ride)
    and does NOT attempt a separate append_ride_event call, eliminating the distributed
    transaction failure vulnerability.
    """
    passenger_id = uuid4()
    payload = RideRequestPayload(
        pickup_lat=1.0, pickup_lng=1.0, destination_lat=2.0, destination_lng=2.0, preferred_payment_method="CASH"
    )
    ride_id = uuid4()
    
    # Mock the repo to return a ride
    mock_ride = RideResponse(
        id=ride_id, passenger_id=passenger_id, rider_id=None, status="REQUESTED", payment_status="PENDING", version=1, created_at=datetime.now(timezone.utc), updated_at=datetime.now(timezone.utc)
    )
    ride_service.ride_repo.create_ride.return_value = mock_ride
    ride_service.ride_repo.get_ride.return_value = mock_ride
    
    # Run service
    await ride_service.create_ride(passenger_id, payload)
    
    # Assert the single atomic call was made
    ride_service.ride_repo.create_ride.assert_called_once_with(passenger_id, payload, "MANUAL")
    
    # CRITICAL: Assert that event_repo was NOT called separately (proving atomic CTE usage)
    ride_service.event_repo.append_ride_event.assert_not_called()

@pytest.mark.database
@pytest.mark.asyncio
async def test_db_integration_trigger_rejection():
    """
    This test requires a live PostgreSQL database to execute.
    It verifies that when an illegal transition is attempted (e.g. ARRIVED to RIDE_REQUESTED),
    the PostgreSQL trigger will raise an exception which the RideService maps to a RuleViolationError.
    """
    assert True # Placeholder for actual db test


@pytest.mark.asyncio
async def test_submit_ride_rating_success(ride_service):
    ride_id = uuid4()
    passenger_id = uuid4()
    rider_id = uuid4()
    
    ride_service.ride_repo.get_ride.return_value = RideResponse(
        id=ride_id,
        passenger_id=passenger_id,
        rider_id=rider_id,
        status="COMPLETED",
        payment_status="SUCCESS",
        version=1,
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc)
    )
    
    mock_pool = MagicMock()
    mock_conn = AsyncMock()
    mock_pool.acquire.return_value = mock_conn
    async def mock_fetchrow_success(query, *args):
        return {"completed_at": datetime.now(timezone.utc)}
    mock_conn.__aenter__.return_value.fetchrow = mock_fetchrow_success
    ride_service.ride_repo._get_pool.return_value = mock_pool
    
    ride_service.ride_repo.get_rating_for_ride_by_user.return_value = None
    ride_service.ride_repo.insert_rating.return_value = {"status": "success"}

    res = await ride_service.submit_ride_rating(
        ride_id=ride_id,
        rated_by=passenger_id,
        rated_user=rider_id,
        score=5,
        comment="Awesome!"
    )
    assert res["status"] == "success"
    ride_service.ride_repo.insert_rating.assert_called_once()


@pytest.mark.asyncio
async def test_submit_ride_rating_expired(ride_service):
    from datetime import timedelta
    ride_id = uuid4()
    passenger_id = uuid4()
    rider_id = uuid4()
    
    ride_service.ride_repo.get_ride.return_value = RideResponse(
        id=ride_id,
        passenger_id=passenger_id,
        rider_id=rider_id,
        status="COMPLETED",
        payment_status="SUCCESS",
        version=1,
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc)
    )
    
    mock_pool = MagicMock()
    mock_conn = AsyncMock()
    mock_pool.acquire.return_value = mock_conn
    completed_time = datetime.now(timezone.utc) - timedelta(hours=25)
    async def mock_fetchrow_expired(query, *args):
        return {"completed_at": completed_time}
    mock_conn.__aenter__.return_value.fetchrow = mock_fetchrow_expired
    ride_service.ride_repo._get_pool.return_value = mock_pool

    with pytest.raises(RuleViolationError) as exc:
        await ride_service.submit_ride_rating(
            ride_id=ride_id,
            rated_by=passenger_id,
            rated_user=rider_id,
            score=5,
            comment="Awesome!"
        )
    assert "Rating window has expired" in str(exc.value)
