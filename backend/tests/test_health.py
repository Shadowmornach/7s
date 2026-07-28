import pytest
from unittest.mock import AsyncMock
from fastapi.testclient import TestClient

def test_health_returns_200(test_client: TestClient):
    response = test_client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy"}

def test_live_returns_200(test_client: TestClient):
    response = test_client.get("/live")
    assert response.status_code == 200
    assert response.json() == {"status": "alive"}

def test_ready_with_db_returns_200(test_client: TestClient, mock_db):
    mock_conn = AsyncMock()
    mock_conn.fetchval.return_value = 1
    mock_db.get_connection.return_value = mock_conn

    response = test_client.get("/ready")
    
    assert response.status_code == 200
    assert response.json() == {"status": "ready"}
    mock_conn.fetchval.assert_called_once_with("SELECT 1")
    mock_db.pool.release.assert_called_once_with(mock_conn)

def test_ready_without_db_returns_503(test_client: TestClient, mock_db):
    mock_db.get_connection.side_effect = Exception("DB Down")

    response = test_client.get("/ready")
    
    assert response.status_code == 503
    assert response.json() == {"detail": {"status": "not ready"}}

def test_metrics_summary_endpoint(test_client: TestClient):
    response = test_client.get("/api/v1/metrics/summary")
    assert response.status_code == 200
    data = response.json()
    assert "error_count_5xx" in data
    assert "avg_sos_response_time_seconds" in data
    assert "payment_success_rate" in data

