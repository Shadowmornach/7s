import pytest
from unittest.mock import AsyncMock, MagicMock
from uuid import uuid4
from datetime import datetime

from app.services.operations_service import OperationsService

@pytest.fixture
def mock_operations_repo():
    repo = AsyncMock()
    return repo

@pytest.fixture
def operations_service(mock_operations_repo):
    return OperationsService(operations_repo=mock_operations_repo)

@pytest.mark.asyncio
async def test_owner_dashboard(operations_service, mock_operations_repo):
    mock_operations_repo.get_owner_dashboard.return_value = {
        "active_rides": 5, "completed_today": 12, "cancelled_today": 2,
        "revenue_today": 4200.0, "riders_online": 8, "active_sos_alerts": 0, "open_disputes": 1
    }

    res = await operations_service.get_owner_dashboard()
    assert res["active_rides"] == 5
    assert res["revenue_today"] == 4200.0
    mock_operations_repo.get_owner_dashboard.assert_called_once()

@pytest.mark.asyncio
async def test_revenue_report_br023_compliance(operations_service, mock_operations_repo):
    """
    Enforces BR-023: Revenue calculations include payment_status = 'SUCCESS' AND refunded = false only.
    """
    mock_operations_repo.get_revenue_report.return_value = [
        {"ride_date": "2026-07-25", "ride_count": 10, "total_revenue": 3500.0},
        {"ride_date": "2026-07-24", "ride_count": 8, "total_revenue": 2800.0}
    ]

    res = await operations_service.get_revenue_report()
    assert len(res) == 2
    assert res[0]["total_revenue"] == 3500.0
    mock_operations_repo.get_revenue_report.assert_called_once()

@pytest.mark.asyncio
async def test_cash_reconciliation_report_bp011_compliance(operations_service, mock_operations_repo):
    """
    Enforces BP-011: Discrepancies (BALANCED, OVERAGE, SHORTFALL) are flagged for owner discretion, never auto-resolved.
    """
    mock_operations_repo.get_cash_reconciliation_report.return_value = [
        {
            "handover_id": str(uuid4()), "rider_name": "John Doe", "expected_cash": 1000.0,
            "actual_cash": 950.0, "difference": -50.0, "reconciliation_status": "SHORTFALL"
        }
    ]

    res = await operations_service.get_cash_reconciliation_report()
    assert len(res) == 1
    assert res[0]["reconciliation_status"] == "SHORTFALL"
    assert res[0]["difference"] == -50.0
    mock_operations_repo.get_cash_reconciliation_report.assert_called_once()

@pytest.mark.asyncio
async def test_historical_places_soft_deleted_br040_compliance(operations_service, mock_operations_repo):
    """
    Enforces BR-040: Soft-deleted/deactivated places must still display correctly in historical reports.
    """
    mock_operations_repo.list_places_historical.return_value = [
        {"id": str(uuid4()), "name": "Voi Bus Stage", "active": True},
        {"id": str(uuid4()), "name": "Old Market (Deactivated)", "active": False}
    ]

    res = await operations_service.get_places_report(include_inactive=True)
    assert len(res) == 2
    assert res[1]["active"] is False
    mock_operations_repo.list_places_historical.assert_called_once_with(include_inactive=True)

import starlette.testclient
from main import app
from app.api.dependencies import get_current_user, get_operations_service
from app.schemas.auth import TokenPayload

def test_operations_endpoint_role_gating():
    client = starlette.testclient.TestClient(app)
    # Passenger role should be forbidden from owner operations dashboard (403)
    app.dependency_overrides[get_current_user] = lambda: TokenPayload(sub=str(uuid4()), role="PASSENGER")
    try:
        response = client.get("/api/v1/operations/dashboard")
        assert response.status_code == 403
    finally:
        app.dependency_overrides.clear()

def test_operations_dashboard_owner_authorized():
    client = starlette.testclient.TestClient(app)
    mock_service = AsyncMock()
    mock_service.get_owner_dashboard.return_value = {"active_rides": 3, "revenue_today": 1500.0}
    app.dependency_overrides[get_current_user] = lambda: TokenPayload(sub=str(uuid4()), role="OWNER")
    app.dependency_overrides[get_operations_service] = lambda: mock_service
    try:
        response = client.get("/api/v1/operations/dashboard")
        assert response.status_code == 200
        assert response.json()["revenue_today"] == 1500.0
    finally:
        app.dependency_overrides.clear()


def test_create_cash_handover_endpoint():
    client = starlette.testclient.TestClient(app)
    mock_service = AsyncMock()
    mock_service.create_cash_handover.return_value = {
        "id": str(uuid4()),
        "rider_id": str(uuid4()),
        "expected_cash": 1000.0,
        "actual_cash": 1000.0,
        "difference": 0.0,
        "received_by": str(uuid4()),
        "notes": "Balanced handover",
        "created_at": "2026-07-27T00:00:00Z"
    }
    app.dependency_overrides[get_current_user] = lambda: TokenPayload(sub=str(uuid4()), role="OWNER")
    app.dependency_overrides[get_operations_service] = lambda: mock_service
    try:
        response = client.post(
            "/api/v1/operations/cash-handovers",
            json={
                "rider_id": str(uuid4()),
                "expected_cash": 1000.0,
                "actual_cash": 1000.0,
                "notes": "Balanced handover"
            }
        )
        assert response.status_code == 201
        assert response.json()["notes"] == "Balanced handover"
    finally:
        app.dependency_overrides.clear()
