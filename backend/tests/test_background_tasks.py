import pytest
import asyncio
from unittest.mock import AsyncMock, MagicMock
from app.services.ride_timeout_scheduler import TimeoutService
from app.core.config import settings

@pytest.mark.asyncio
async def test_timeout_service_sweep(mock_db):
    mock_conn = AsyncMock()
    mock_conn.execute.return_value = "INSERT 0 2"
    
    mock_acquire = AsyncMock()
    mock_acquire.__aenter__.return_value = mock_conn
    mock_acquire.__aexit__.return_value = None
    mock_db.pool.acquire = MagicMock(return_value=mock_acquire)

    service = TimeoutService(pool=mock_db.pool)
    await service._sweep()

    mock_db.pool.acquire.assert_called_once()
    mock_conn.execute.assert_called_once()

@pytest.mark.asyncio
async def test_timeout_service_lifecycle(mock_db):
    service = TimeoutService(pool=mock_db.pool)
    
    # Temporarily speed up sweep interval for test
    original_interval = settings.TIMEOUT_SWEEP_INTERVAL_SECONDS
    settings.TIMEOUT_SWEEP_INTERVAL_SECONDS = 0.01
    
    mock_conn = AsyncMock()
    mock_conn.execute.return_value = "INSERT 0 0"
    
    mock_acquire = AsyncMock()
    mock_acquire.__aenter__.return_value = mock_conn
    mock_acquire.__aexit__.return_value = None
    mock_db.pool.acquire = MagicMock(return_value=mock_acquire)

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
    service = TimeoutService(pool=mock_db.pool)
    settings.TIMEOUT_SWEEP_INTERVAL_SECONDS = 0.01
    
    # Simulate DB being down when acquire is called
    mock_acquire = MagicMock(side_effect=Exception("Database connection pool exhausted"))
    mock_db.pool.acquire = mock_acquire
    
    service.start()
    assert service.is_running
    
    await asyncio.sleep(0.2)
    
    # Worker should still be running despite the exception
    assert service.is_running
    
    # Verify the loop retried multiple times
    assert mock_db.pool.acquire.call_count >= 2
    
    await service.stop()
    assert not service.is_running
