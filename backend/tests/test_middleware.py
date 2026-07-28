import uuid
from fastapi import FastAPI
from fastapi.testclient import TestClient

def test_request_id_header_present(test_client: TestClient):
    # Any route that hits the app should get an x-request-id header
    response = test_client.get("/docs")
    assert "x-request-id" in response.headers

def test_request_id_is_valid_uuid(test_client: TestClient):
    response = test_client.get("/docs")
    req_id = response.headers.get("x-request-id")
    assert req_id is not None
    # Will raise ValueError if not valid UUID hex
    parsed = uuid.UUID(hex=req_id)
    assert parsed.hex == req_id

def test_different_requests_different_ids(test_client: TestClient):
    response1 = test_client.get("/docs")
    response2 = test_client.get("/docs")
    assert response1.headers.get("x-request-id") != response2.headers.get("x-request-id")

def test_metrics_endpoint_returns_200(test_client: TestClient):
    response = test_client.get("/metrics")
    assert response.status_code == 200
    assert "http_requests_total" in response.text
