import pytest
from uuid import uuid4
from fastapi.testclient import TestClient
from unittest.mock import AsyncMock, patch
from starlette.websockets import WebSocketDisconnect

from main import app
from app.api.dependencies import get_pubsub_service, get_ride_service
from app.schemas.auth import TokenPayload

client = TestClient(app)

@pytest.fixture
def mock_dependencies():
    mock_pubsub = AsyncMock()
    mock_ride = AsyncMock()
    app.dependency_overrides[get_pubsub_service] = lambda: mock_pubsub
    app.dependency_overrides[get_ride_service] = lambda: mock_ride
    yield mock_pubsub, mock_ride
    app.dependency_overrides.clear()

def test_websocket_auth_failure_no_protocol():
    ride_id = uuid4()
    with pytest.raises(WebSocketDisconnect) as exc:
        with client.websocket_connect(f"/ws/rides/{ride_id}") as websocket:
            pass
    assert exc.value.code == 1008

def test_websocket_auth_failure_invalid_token(mock_dependencies):
    ride_id = uuid4()
    with pytest.raises(WebSocketDisconnect) as exc:
        with client.websocket_connect(f"/ws/rides/{ride_id}", subprotocols=["invalid_token"]) as websocket:
            pass
    assert exc.value.code == 1008

def test_websocket_success_with_subprotocol(mock_dependencies):
    mock_pubsub, mock_ride = mock_dependencies
    ride_id = uuid4()
    
    async def mock_subscribe(channel):
        yield {"status": "REQUESTED"}

    mock_pubsub.subscribe = mock_subscribe
    
    # Mock get_current_user to simulate valid token
    with patch("app.api.ride_websockets.get_current_user", AsyncMock(return_value=TokenPayload(sub=str(uuid4()), role="PASSENGER"))):
        with client.websocket_connect(f"/ws/rides/{ride_id}", subprotocols=["valid_legacy_token"]) as websocket:
            data1 = websocket.receive_json()
            assert data1 == {"status": "REQUESTED"}
