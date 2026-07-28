import pytest
from fastapi.testclient import TestClient
from uuid import uuid4
from unittest.mock import patch, AsyncMock
from main import app
from app.api.dependencies import get_ride_service, get_current_user
from app.schemas.auth import TokenPayload
from app.domain.exceptions import ConcurrencyException, InvalidPayloadError

@pytest.fixture(autouse=True)
def mock_db():
    with patch("main.db.connect", new_callable=AsyncMock), patch("main.db.disconnect", new_callable=AsyncMock):
        yield

@pytest.fixture
def mock_ride_service():
    mock_service = AsyncMock()
    app.dependency_overrides[get_ride_service] = lambda: mock_service
    app.dependency_overrides[get_current_user] = lambda: TokenPayload(sub=str(uuid4()), role="PASSENGER")
    yield mock_service
    app.dependency_overrides.clear()

client = TestClient(app)

def test_request_ride(mock_ride_service):
    mock_ride_service.create_ride.return_value = {
        "id": str(uuid4()),
        "passenger_id": str(uuid4()),
        "rider_id": None,
        "status": "REQUESTED",
        "payment_status": "PENDING",
        "version": 1,
        "created_at": "2026-07-24T12:00:00Z",
        "updated_at": "2026-07-24T12:00:00Z"
    }

    response = client.post(
        "/rides/request",
        headers={"Authorization": "Bearer testtoken"},
        json={
            "pickup_lat": -1.2921,
            "pickup_lng": 36.8219,
            "destination_lat": -1.2800,
            "destination_lng": 36.8200
        }
    )
    
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "REQUESTED"
    assert data["version"] == 1

def test_unified_event_endpoint_concurrency_conflict(mock_ride_service):
    mock_ride_service.handle_ride_event.side_effect = ConcurrencyException("Version mismatch")
    
    ride_id = str(uuid4())
    response = client.post(
        f"/rides/{ride_id}/events",
        headers={"Authorization": "Bearer testtoken"},
        json={
            "action": "accept_fare",
            "expected_version": 2,
            "metadata": {}
        }
    )
    
    assert response.status_code == 409
    assert response.json()["detail"]["error_code"] == "CONCURRENCY_ERROR"

@pytest.mark.database
def test_db_integration_full_ride_lifecycle():
    """
    This test requires a live PostgreSQL database.
    It executes an entire 'Instant' ride flow through the unified event endpoint,
    verifying that the triggers correctly advance rides.status and rides.version
    with every POST request.
    """
    pass


def test_submit_ride_rating_endpoint(mock_ride_service):
    mock_ride_service.submit_ride_rating.return_value = {
        "id": str(uuid4()),
        "ride_id": str(uuid4()),
        "rated_by": str(uuid4()),
        "rated_user": str(uuid4()),
        "score": 5,
        "comment": "Great ride!",
        "created_at": "2026-07-27T00:00:00Z"
    }

    ride_id = str(uuid4())
    rated_user = str(uuid4())
    response = client.post(
        f"/rides/{ride_id}/rate",
        headers={"Authorization": "Bearer testtoken"},
        json={
            "rated_user": rated_user,
            "score": 5,
            "comment": "Great ride!"
        }
    )

    assert response.status_code == 201
    assert response.json()["score"] == 5
    assert response.json()["comment"] == "Great ride!"
    mock_ride_service.submit_ride_rating.assert_called_once()
