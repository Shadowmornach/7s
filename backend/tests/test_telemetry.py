import pytest
from fastapi.testclient import TestClient
from uuid import uuid4, UUID
from unittest.mock import AsyncMock, patch
from datetime import datetime, timezone
from main import app
from app.api.dependencies import get_ride_service, get_current_user
from app.schemas.auth import TokenPayload
from app.schemas.rides import RideResponse
from app.services.ride_service import RideService
from app.domain.exceptions import UnauthorizedError

@pytest.fixture(autouse=True)
def mock_db():
    with patch("main.db.connect", new_callable=AsyncMock), patch("main.db.disconnect", new_callable=AsyncMock):
        yield

# =====================================================================
# API ENDPOINT TESTS
# =====================================================================

def test_update_location_api_success():
    ride_id = uuid4()
    rider_id = uuid4()
    
    mock_service = AsyncMock()
    # Mock return value of update_rider_location to match RideResponse schema
    mock_service.update_rider_location.return_value = RideResponse(
        id=ride_id,
        passenger_id=uuid4(),
        rider_id=rider_id,
        status="IN_PROGRESS",
        payment_status="PENDING",
        version=5,
        active_sos_id=None,
        active_sos_severity=None,
        active_sos_status=None,
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc)
    )
    
    app.dependency_overrides[get_current_user] = lambda: TokenPayload(sub=str(rider_id), role="RIDER")
    app.dependency_overrides[get_ride_service] = lambda: mock_service
    
    client = TestClient(app)
    response = client.post(
        f"/rides/{ride_id}/location",
        headers={"Authorization": "Bearer testtoken"},
        json={"latitude": -3.3962, "longitude": 38.5561}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "IN_PROGRESS"
    assert data["version"] == 5
    mock_service.update_rider_location.assert_called_once_with(
        ride_id=ride_id,
        rider_id=rider_id,
        latitude=-3.3962,
        longitude=38.5561
    )
    app.dependency_overrides.clear()

def test_update_location_api_forbidden_for_passenger():
    ride_id = uuid4()
    passenger_id = uuid4()
    
    app.dependency_overrides[get_current_user] = lambda: TokenPayload(sub=str(passenger_id), role="PASSENGER")
    
    client = TestClient(app)
    response = client.post(
        f"/rides/{ride_id}/location",
        headers={"Authorization": "Bearer testtoken"},
        json={"latitude": -3.3962, "longitude": 38.5561}
    )
    
    assert response.status_code == 403
    assert "Required roles" in response.json()["detail"]
    app.dependency_overrides.clear()

# =====================================================================
# SERVICE LAYER TESTS
# =====================================================================

@pytest.mark.asyncio
async def test_ride_service_update_location_appends_event():
    ride_id = uuid4()
    rider_id = uuid4()
    passenger_id = uuid4()
    
    # Mock repos
    mock_ride_repo = AsyncMock()
    mock_event_repo = AsyncMock()
    mock_pubsub = AsyncMock()
    
    ride_response = RideResponse(
        id=ride_id,
        passenger_id=passenger_id,
        rider_id=rider_id,
        status="IN_PROGRESS",
        payment_status="PENDING",
        version=4,
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc)
    )
    mock_ride_repo.get_ride.return_value = ride_response
    
    service = RideService(ride_repo=mock_ride_repo, event_repo=mock_event_repo, pubsub_service=mock_pubsub)
    
    # Execute service method
    res = await service.update_rider_location(ride_id, rider_id, -3.3962, 38.5561)
    
    # Assertions
    assert res.version == 4
    mock_event_repo.append_ride_event.assert_called_once_with(
        ride_id=ride_id,
        event_type="TELEMETRY_UPDATE",
        actor_id=rider_id,
        lat=-3.3962,
        lng=38.5561,
        metadata={"source": "telemetry"}
    )
    mock_pubsub.publish.assert_called_once()

@pytest.mark.asyncio
async def test_ride_service_update_location_wrong_rider_rejected():
    ride_id = uuid4()
    rider_id = uuid4()
    other_rider_id = uuid4()
    passenger_id = uuid4()
    
    mock_ride_repo = AsyncMock()
    mock_event_repo = AsyncMock()
    mock_pubsub = AsyncMock()
    
    # The ride belongs to rider_id, not other_rider_id
    ride_response = RideResponse(
        id=ride_id,
        passenger_id=passenger_id,
        rider_id=rider_id,
        status="IN_PROGRESS",
        payment_status="PENDING",
        version=4,
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc)
    )
    mock_ride_repo.get_ride.return_value = ride_response
    
    service = RideService(ride_repo=mock_ride_repo, event_repo=mock_event_repo, pubsub_service=mock_pubsub)
    
    # passenger_id tries to post location, must fail with the "Only the assigned rider" message
    with pytest.raises(UnauthorizedError) as exc_info:
        await service.update_rider_location(ride_id, passenger_id, -3.3962, 38.5561)
        
    assert "Only the assigned rider" in str(exc_info.value)
    mock_event_repo.append_ride_event.assert_not_called()

@pytest.mark.asyncio
async def test_ride_service_update_location_unrelated_user_rejected():
    ride_id = uuid4()
    rider_id = uuid4()
    other_user_id = uuid4()
    passenger_id = uuid4()
    
    mock_ride_repo = AsyncMock()
    mock_event_repo = AsyncMock()
    mock_pubsub = AsyncMock()
    
    ride_response = RideResponse(
        id=ride_id,
        passenger_id=passenger_id,
        rider_id=rider_id,
        status="IN_PROGRESS",
        payment_status="PENDING",
        version=4,
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc)
    )
    mock_ride_repo.get_ride.return_value = ride_response
    
    service = RideService(ride_repo=mock_ride_repo, event_repo=mock_event_repo, pubsub_service=mock_pubsub)
    
    # unrelated user tries to post location, must fail with standard access rejection
    with pytest.raises(UnauthorizedError) as exc_info:
        await service.update_rider_location(ride_id, other_user_id, -3.3962, 38.5561)
        
    assert "is not authorized to access ride" in str(exc_info.value)
    mock_event_repo.append_ride_event.assert_not_called()
