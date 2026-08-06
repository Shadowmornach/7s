import pytest
from fastapi.testclient import TestClient
from uuid import uuid4
import asyncio

from main import app
from app.core.rate_limit import login_rate_limiter

client = TestClient(app)

def test_oversized_payload_rejection():
    # Attempt to send a payload slightly larger than MAX_REQUEST_SIZE_BYTES
    # Config is 2MB, so we send 2.1MB
    large_payload = "a" * (2 * 1024 * 1024 + 100)
    response = client.post(
        "/rides/request",
        json={"payload": large_payload},
        headers={"Content-Length": str(len(large_payload))}
    )
    # The middleware should intercept this before Pydantic parsing
    assert response.status_code == 413
    assert response.json()["message"] == "Payload too large"

def test_validation_error_sanitization():
    # Send a request missing required fields to trigger validation error
    response = client.post(
        "/auth/login",
        json={} # Missing email and password
    )
    
    assert response.status_code == 422
    data = response.json()
    assert data["message"] == "Validation failed"
    # Ensure internal types/classes are not leaked
    assert "ctx" not in data["errors"][0]
    assert "type" not in data["errors"][0]
    assert "input" not in data["errors"][0]
    assert data["errors"][0]["field"] == "body.email"

@pytest.mark.asyncio
async def test_rate_limiter_bounded_memory():
    # Fill the rate limiter to max_keys
    original_max = login_rate_limiter.max_keys
    login_rate_limiter.max_keys = 5 # temporarily reduce for testing
    
    login_rate_limiter._history.clear()
    
    for i in range(10):
        await login_rate_limiter.check_rate_limit(f"user_{i}")
        
    # The size should not exceed 5 despite 10 unique users
    assert len(login_rate_limiter._history) == 5
    
    # The oldest users (0 to 4) should have been evicted
    assert "user_0" not in login_rate_limiter._history
    assert "user_9" in login_rate_limiter._history
    
    # Restore max
    login_rate_limiter.max_keys = original_max
