import pytest
from fastapi.testclient import TestClient
from uuid import uuid4
from decimal import Decimal
from unittest.mock import patch, AsyncMock
from main import app
from app.api.dependencies import get_current_user, get_place_service
from app.schemas.auth import TokenPayload
from app.schemas.places import PlaceResponse, PlaceType, PlaceOrigin
from app.domain.exceptions import UnauthorizedError, RuleViolationError
from datetime import datetime, timezone

client = TestClient(app)

@pytest.fixture(autouse=True)
def mock_db():
    with patch("main.db.connect", new_callable=AsyncMock), patch("main.db.disconnect", new_callable=AsyncMock):
        yield

def mock_place_response(place_id=None, place_type=PlaceType.USER, created_by=None):
    if not place_id:
        place_id = uuid4()
    if not created_by:
        created_by = uuid4()
    return PlaceResponse(
        id=place_id,
        name="Test Place",
        latitude=Decimal("-1.2921"),
        longitude=Decimal("36.8219"),
        place_type=place_type,
        origin=PlaceOrigin.MANUAL,
        created_by=created_by,
        usage_count=0,
        active=True,
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc)
    )

def test_create_system_place_as_owner():
    user_id = str(uuid4())
    app.dependency_overrides[get_current_user] = lambda: TokenPayload(sub=user_id, role="OWNER")
    
    mock_service = AsyncMock()
    mock_service.create_place.return_value = mock_place_response(place_type=PlaceType.SYSTEM)
    app.dependency_overrides[get_place_service] = lambda: mock_service

    response = client.post("/api/v1/places/", json={
        "name": "System Hub",
        "latitude": -1.2921,
        "longitude": 36.8219,
        "place_type": "SYSTEM",
        "origin": "MANUAL"
    })
    
    assert response.status_code == 201
    assert response.json()["place_type"] == "SYSTEM"

def test_create_system_place_as_user_rejected():
    user_id = str(uuid4())
    app.dependency_overrides[get_current_user] = lambda: TokenPayload(sub=user_id, role="PASSENGER")
    
    mock_service = AsyncMock()
    mock_service.create_place.side_effect = UnauthorizedError("Only owners can create SYSTEM places")
    app.dependency_overrides[get_place_service] = lambda: mock_service

    response = client.post("/api/v1/places/", json={
        "name": "System Hub",
        "latitude": -1.2921,
        "longitude": 36.8219,
        "place_type": "SYSTEM",
        "origin": "MANUAL"
    })
    
    assert response.status_code == 403
    assert response.json()["detail"]["error_code"] == "UNAUTHORIZED"

def test_create_place_outside_service_area_rejected():
    user_id = str(uuid4())
    app.dependency_overrides[get_current_user] = lambda: TokenPayload(sub=user_id, role="PASSENGER")
    
    mock_service = AsyncMock()
    mock_service.create_place.side_effect = RuleViolationError("Pickup location is outside the service area.")
    app.dependency_overrides[get_place_service] = lambda: mock_service

    response = client.post("/api/v1/places/", json={
        "name": "Far Away Place",
        "latitude": 40.7128,
        "longitude": -74.0060,
        "place_type": "USER",
        "origin": "MANUAL"
    })
    
    assert response.status_code == 400
    assert response.json()["detail"]["error_code"] == "RULE_VIOLATION"
