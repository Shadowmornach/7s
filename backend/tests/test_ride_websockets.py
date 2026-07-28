import pytest
import asyncio
from fastapi.testclient import TestClient
from uuid import uuid4
from unittest.mock import AsyncMock

from main import app
from app.api.dependencies import get_pubsub_service, get_current_user
from app.schemas.auth import TokenPayload

@pytest.fixture
def mock_pubsub():
    from app.api.dependencies import get_ride_service
    mock = AsyncMock()
    mock_ride_service = AsyncMock()
    app.dependency_overrides[get_pubsub_service] = lambda: mock
    app.dependency_overrides[get_ride_service] = lambda: mock_ride_service
    yield mock
    app.dependency_overrides.clear()

client = TestClient(app)

from starlette.websockets import WebSocketDisconnect

def test_websocket_auth_failure():
    ride_id = uuid4()
    with pytest.raises(WebSocketDisconnect) as exc:
        with client.websocket_connect(f"/ws/rides/{ride_id}?token=invalid") as websocket:
            pass
    assert exc.value.code == 1008

from unittest.mock import patch

def test_websocket_success(mock_pubsub):
    ride_id = uuid4()
    
    # Mock the subscribe generator
    async def mock_subscribe(channel):
        yield {"status": "REQUESTED"}
        yield {"status": "RIDER_ASSIGNED"}

    mock_pubsub.subscribe = mock_subscribe
    
    with patch("app.api.ride_websockets.get_current_user", AsyncMock(return_value=TokenPayload(sub=str(uuid4()), role="PASSENGER"))):
        with client.websocket_connect(f"/ws/rides/{ride_id}?token=valid_mock_token") as websocket:
            data1 = websocket.receive_json()
            assert data1 == {"status": "REQUESTED"}
            
            data2 = websocket.receive_json()
            assert data2 == {"status": "RIDER_ASSIGNED"}
