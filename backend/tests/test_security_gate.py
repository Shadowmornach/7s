import pytest
from fastapi.testclient import TestClient
from uuid import uuid4
from unittest.mock import patch, AsyncMock
from main import app
from app.api.dependencies import get_ride_service, get_current_user, get_auth_service
from app.schemas.auth import TokenPayload
from app.domain.exceptions import UnauthorizedError, RuleViolationError

@pytest.fixture(autouse=True)
def mock_db():
    with patch("main.db.connect", new_callable=AsyncMock), patch("main.db.disconnect", new_callable=AsyncMock):
        yield

client = TestClient(app)

def test_unauthenticated_get_rides_rejected():
    app.dependency_overrides.clear()
    response = client.get("/rides")
    assert response.status_code == 401

def test_unauthenticated_get_single_ride_rejected():
    app.dependency_overrides.clear()
    response = client.get(f"/rides/{uuid4()}")
    assert response.status_code == 401

def test_authorized_get_ride_ownership_denied():
    user_id = str(uuid4())
    mock_service = AsyncMock()
    mock_service.get_ride.side_effect = UnauthorizedError("Access denied")
    
    app.dependency_overrides[get_ride_service] = lambda: mock_service
    app.dependency_overrides[get_current_user] = lambda: TokenPayload(sub=user_id, role="PASSENGER")
    
    try:
        response = client.get(f"/rides/{uuid4()}", headers={"Authorization": "Bearer token"})
        assert response.status_code == 403
        assert response.json()["detail"]["error_code"] == "UNAUTHORIZED"
    finally:
        app.dependency_overrides.clear()

def test_security_headers_present():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.headers.get("x-content-type-options") == "nosniff"
    assert response.headers.get("x-frame-options") == "DENY"
    assert response.headers.get("referrer-policy") == "strict-origin-when-cross-origin"

def test_login_rate_limiting():
    mock_auth_service = AsyncMock()
    mock_auth_service.verify_otp_and_login.side_effect = RuleViolationError("Invalid credentials")
    app.dependency_overrides[get_auth_service] = lambda: mock_auth_service
    
    try:
        phone = f"+254700{uuid4().hex[:6]}"
        # Make 5 calls (limit is 5)
        for _ in range(5):
            client.post("/auth/login", json={"phone_number": phone, "otp": "123456"})
        
        # 6th call should be 429 Rate Limited
        resp = client.post("/auth/login", json={"phone_number": phone, "otp": "123456"})
        assert resp.status_code == 429
        assert resp.json()["detail"]["error_code"] == "RATE_LIMIT_EXCEEDED"
    finally:
        app.dependency_overrides.clear()
