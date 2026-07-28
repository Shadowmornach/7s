import pytest
from fastapi.testclient import TestClient
from unittest.mock import AsyncMock

from main import app
from app.db.connection import db

@pytest.fixture
def test_client():
    return TestClient(app)

@pytest.fixture
def mock_db(monkeypatch):
    monkeypatch.setattr(db, "connect", AsyncMock())
    monkeypatch.setattr(db, "disconnect", AsyncMock())
    monkeypatch.setattr(db, "get_connection", AsyncMock())
    monkeypatch.setattr(db, "pool", AsyncMock())
    return db
