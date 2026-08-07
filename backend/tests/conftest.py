import sys
import pytest
from fastapi.testclient import TestClient
from unittest.mock import MagicMock, AsyncMock

if "asyncpg" not in sys.modules:
    try:
        import asyncpg
    except ImportError:
        mock_asyncpg = MagicMock()
        class PostgresError(Exception): pass
        class RaiseError(PostgresError): pass
        class CheckViolationError(PostgresError): pass
        class IntegrityConstraintViolationError(PostgresError): pass

        mock_asyncpg.exceptions.PostgresError = PostgresError
        mock_asyncpg.exceptions.RaiseError = RaiseError
        mock_asyncpg.exceptions.CheckViolationError = CheckViolationError
        mock_asyncpg.exceptions.IntegrityConstraintViolationError = IntegrityConstraintViolationError

        sys.modules["asyncpg"] = mock_asyncpg
        sys.modules["asyncpg.exceptions"] = mock_asyncpg.exceptions

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
