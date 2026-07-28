import pytest
import asyncio
from unittest.mock import AsyncMock
from app.services.ride_timeout_scheduler import TimeoutService
from app.core.config import settings

@pytest.mark.asyncio
async def test_timeout_service_sweep(mock_db):
    mock_conn = AsyncMock()
    mock_conn.execute.return_value = "INSERT 0 2"
    mock_db.get_connection.return_value = mock_conn

    service = TimeoutService()
    await service._sweep()

    mock_db.get_connection.assert_called_once()
    mock_conn.execute.assert_called_once()
    mock_db.pool.release.assert_called_once_with(mock_conn)

@pytest.mark.asyncio
async def test_timeout_service_lifecycle(mock_db):
    service = TimeoutService()
    
    # Temporarily speed up sweep interval for test
    original_interval = settings.TIMEOUT_SWEEP_INTERVAL_SECONDS
    settings.TIMEOUT_SWEEP_INTERVAL_SECONDS = 0.01
    
    # Mock execute to prevent warning about un-awaited coroutine string
    mock_conn = AsyncMock()
    mock_conn.execute.return_value = "INSERT 0 0"
    mock_db.get_connection.return_value = mock_conn

    service.start()
    assert service.is_running
    
    await asyncio.sleep(0.05)
    
    await service.stop()
    assert not service.is_running
    
    settings.TIMEOUT_SWEEP_INTERVAL_SECONDS = original_interval

@pytest.mark.asyncio
async def test_timeout_service_resilience_to_db_failure(mock_db, caplog):
    """
    Gate 7 Resilience Test: Prove that the worker catches connection failures
    and stays alive to retry instead of silently crashing.
    """
    service = TimeoutService()
    settings.TIMEOUT_SWEEP_INTERVAL_SECONDS = 0.01
    
    # Simulate DB being down
    mock_db.get_connection.side_effect = Exception("Database connection pool exhausted")
    
    service.start()
    assert service.is_running
    
    await asyncio.sleep(0.2)
    
    # Worker should still be running despite the exception
    assert service.is_running
    
    # Verify the loop retried multiple times
    assert mock_db.get_connection.call_count >= 2
    
    await service.stop()
    assert not service.is_running
