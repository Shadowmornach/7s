import time
import asyncio
from typing import Dict, List
from fastapi import HTTPException, status
from app.core.config import settings

class RateLimiterInterface:
    async def check_rate_limit(self, key: str) -> None:
        raise NotImplementedError

from collections import OrderedDict

class InMemoryRateLimiter(RateLimiterInterface):
    def __init__(self, max_calls: int, period_seconds: int, max_keys: int, error_message: str = "Too many requests. Please try again later."):
        self.max_calls = max_calls
        self.period_seconds = period_seconds
        self.max_keys = max_keys
        self._history: OrderedDict[str, List[float]] = OrderedDict()
        self._lock = asyncio.Lock()

    async def check_rate_limit(self, key: str) -> None:
        async with self._lock:
            now = time.time()
            timestamps = self._history.get(key, [])
            
            # Prune old timestamps
            cutoff = now - self.period_seconds
            valid_timestamps = [t for t in timestamps if t > cutoff]
            
            if len(valid_timestamps) >= self.max_calls:
                # Still move to end if they are repeatedly hitting it
                self._history.move_to_end(key)
                raise HTTPException(
                    status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                    detail={"error_code": "RATE_LIMIT_EXCEEDED", "message": getattr(self, "error_message", "Too many requests. Please try again later.")}
                )
            
            valid_timestamps.append(now)
            self._history[key] = valid_timestamps
            self._history.move_to_end(key)
            
            # LRU Eviction to bound memory
            if len(self._history) > self.max_keys:
                self._history.popitem(last=False)

login_rate_limiter = InMemoryRateLimiter(
    max_calls=settings.LOGIN_RATE_LIMIT_CALLS,
    period_seconds=settings.LOGIN_RATE_LIMIT_PERIOD_SECONDS,
    max_keys=settings.RATE_LIMIT_MAX_KEYS,
    error_message="Too many login attempts. Please try again later."
)

webhook_ip_rate_limiter = InMemoryRateLimiter(
    max_calls=settings.WEBHOOK_IP_RATE_LIMIT_CALLS,
    period_seconds=settings.WEBHOOK_IP_RATE_LIMIT_PERIOD,
    max_keys=settings.RATE_LIMIT_MAX_KEYS,
    error_message="Too many webhook requests."
)

class InMemoryCooldown:
    """
    Returns True if allowed (no cooldown active), False if cooling down.
    Does not raise exceptions. Safe for concurrent requests.
    """
    def __init__(self, period_seconds: int, max_keys: int):
        self.period_seconds = period_seconds
        self.max_keys = max_keys
        self._history: OrderedDict[str, float] = OrderedDict()
        self._lock = asyncio.Lock()

    async def check_allow(self, key: str) -> bool:
        async with self._lock:
            now = time.time()
            last_time = self._history.get(key)
            
            if last_time and (now - last_time) < self.period_seconds:
                # Move to end since it was accessed
                self._history.move_to_end(key)
                return False
                
            self._history[key] = now
            self._history.move_to_end(key)
            
            # LRU Eviction
            if len(self._history) > self.max_keys:
                self._history.popitem(last=False)
                
            return True

webhook_payment_cooldown = InMemoryCooldown(
    period_seconds=settings.WEBHOOK_PAYMENT_COOLDOWN_SECONDS,
    max_keys=settings.RATE_LIMIT_MAX_KEYS
)
