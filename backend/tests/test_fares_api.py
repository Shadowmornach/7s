import pytest
from fastapi.testclient import TestClient
from uuid import uuid4
from decimal import Decimal
from unittest.mock import patch, AsyncMock
from main import app
from app.api.dependencies import get_current_user, get_fare_service
from app.schemas.auth import TokenPayload
from app.schemas.fares import RouteQuoteResponse
from app.domain.exceptions import RuleViolationError

client = TestClient(app)

@pytest.fixture(autouse=True)
def mock_db():
    with patch("main.db.connect", new_callable=AsyncMock), patch("main.db.disconnect", new_callable=AsyncMock):
        yield

def test_fare_quote_with_template():
    user_id = str(uuid4())
    app.dependency_overrides[get_current_user] = lambda: TokenPayload(sub=user_id, role="PASSENGER")
    
    mock_service = AsyncMock()
    mock_service.get_route_quote.return_value = RouteQuoteResponse(
        fare=Decimal("500.00"),
        estimated_distance_km=Decimal("5.2"),
        estimated_time_seconds=900,
        is_template_match=True
    )
    app.dependency_overrides[get_fare_service] = lambda: mock_service

    response = client.post("/api/v1/fare-templates/quote", json={
        "pickup_lat": -1.2921,
        "pickup_lng": 36.8219,
        "destination_lat": -1.2921,
        "destination_lng": 36.8219,
        "pickup_place_id": str(uuid4()),
        "destination_place_id": str(uuid4())
    })
    
    assert response.status_code == 200
    data = response.json()
    assert data["fare"] == "500.00"
    assert data["is_template_match"] is True

def test_fare_quote_no_template_calculates_distance_only():
    user_id = str(uuid4())
    app.dependency_overrides[get_current_user] = lambda: TokenPayload(sub=user_id, role="PASSENGER")
    
    mock_service = AsyncMock()
    # ORS fallback response
    mock_service.get_route_quote.return_value = RouteQuoteResponse(
        fare=None,
        estimated_distance_km=Decimal("12.5"),
        estimated_time_seconds=1800,
        is_template_match=False
    )
    app.dependency_overrides[get_fare_service] = lambda: mock_service

    response = client.post("/api/v1/fare-templates/quote", json={
        "pickup_lat": -1.2921,
        "pickup_lng": 36.8219,
        "destination_lat": -1.2921,
        "destination_lng": 36.8219
    })
    
    assert response.status_code == 200
    data = response.json()
    assert data["fare"] is None
    assert data["estimated_distance_km"] == "12.5"
    assert data["is_template_match"] is False

def test_fare_quote_outside_radius_rejected():
    user_id = str(uuid4())
    app.dependency_overrides[get_current_user] = lambda: TokenPayload(sub=user_id, role="PASSENGER")
    
    mock_service = AsyncMock()
    mock_service.get_route_quote.side_effect = RuleViolationError("Destination is outside the service area.")
    app.dependency_overrides[get_fare_service] = lambda: mock_service

    response = client.post("/api/v1/fare-templates/quote", json={
        "pickup_lat": -1.2921,
        "pickup_lng": 36.8219,
        "destination_lat": 40.7128,
        "destination_lng": -74.0060
    })
    
    assert response.status_code == 400
    assert response.json()["detail"]["error_code"] == "RULE_VIOLATION"


def test_delete_fare_template_endpoint():
    app.dependency_overrides[get_current_user] = lambda: TokenPayload(sub=str(uuid4()), role="OWNER")
    mock_service = AsyncMock()
    app.dependency_overrides[get_fare_service] = lambda: mock_service
    template_id = str(uuid4())
    try:
        response = client.delete(f"/api/v1/fare-templates/{template_id}")
        assert response.status_code == 204
        mock_service.deactivate_template.assert_called_once()
    finally:
        app.dependency_overrides.clear()


def test_delete_fare_template_forbidden_for_passenger():
    app.dependency_overrides[get_current_user] = lambda: TokenPayload(sub=str(uuid4()), role="PASSENGER")
    template_id = str(uuid4())
    try:
        response = client.delete(f"/api/v1/fare-templates/{template_id}")
        assert response.status_code == 403
    finally:
        app.dependency_overrides.clear()
