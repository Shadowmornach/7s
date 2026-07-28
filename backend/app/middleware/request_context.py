import uuid
import time
import logging
from contextvars import ContextVar
from starlette.types import ASGIApp, Receive, Scope, Send
from app.core.metrics import http_requests_total, http_request_duration

request_id_var: ContextVar[str] = ContextVar("request_id", default="")

logger = logging.getLogger("7s.http")

EXCLUDED_PATHS = {"/health", "/live", "/ready", "/metrics"}

class RequestContextMiddleware:
    """Pure ASGI middleware — no body buffering, no task spawning."""

    def __init__(self, app: ASGIApp):
        self.app = app

    async def __call__(self, scope: Scope, receive: Receive, send: Send):
        if scope["type"] not in ("http", "websocket"):
            await self.app(scope, receive, send)
            return
            
        path = scope.get("path", "")
        if path in EXCLUDED_PATHS:
            await self.app(scope, receive, send)
            return

        rid = uuid.uuid4().hex
        token = request_id_var.set(rid)
        start = time.perf_counter()
        status_code = 0

        async def send_wrapper(message):
            nonlocal status_code
            if message["type"] == "http.response.start":
                status_code = message["status"]
                headers = list(message.get("headers", []))
                headers.append((b"x-request-id", rid.encode()))
                message["headers"] = headers
            await send(message)

        try:
            await self.app(scope, receive, send_wrapper)
        finally:
            duration = (time.perf_counter() - start) * 1000
            
            # Prometheus metrics (duration in seconds)
            http_request_duration.labels(method=scope.get("method", ""), path=path).observe(duration / 1000.0)
            http_requests_total.labels(method=scope.get("method", ""), path=path, status=str(status_code)).inc()
            
            logger.info(
                "request completed",
                extra={
                    "request_id": rid,
                    "method": scope.get("method", ""),
                    "path": path,
                    "status_code": status_code,
                    "duration_ms": round(duration, 2),
                },
            )
            request_id_var.reset(token)
