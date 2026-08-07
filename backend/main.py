from contextlib import asynccontextmanager
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
import logging
from prometheus_client import make_asgi_app
from app.api import rides, health, auth, ride_websockets, places, fares, payments, operations
from app.db.connection import db
from app.core.config import settings
from app.core.logging import setup_logging
from fastapi.middleware.cors import CORSMiddleware
from app.middleware.request_context import RequestContextMiddleware, request_id_var
from app.middleware.security_headers import SecurityHeadersMiddleware
from app.services.ride_timeout_scheduler import TimeoutService

timeout_service = TimeoutService()

@asynccontextmanager
async def lifespan(app: FastAPI):
    try:
        await db.connect()
    except Exception as e:
        logging.getLogger("7s.startup").warning(f"Database connection unavailable during startup: {e}")
    timeout_service.start()
    yield
    await timeout_service.stop()
    await db.disconnect()

def create_app() -> FastAPI:
    setup_logging(settings.LOG_LEVEL)
    
    app = FastAPI(
        title="7s TOMS Backend",
        version="1.0.0",
        lifespan=lifespan,
        docs_url="/docs" if settings.DEBUG else None,
        redoc_url="/redoc" if settings.DEBUG else None,
        openapi_url="/openapi.json" if settings.DEBUG else None,
    )


    app.include_router(rides.router)
    app.include_router(health.router)
    app.include_router(auth.router)
    app.include_router(ride_websockets.router)
    app.include_router(places.router, prefix="/api/v1/places", tags=["Places"])
    app.include_router(fares.router, prefix="/api/v1/fare-templates", tags=["Fare Templates"])
    app.include_router(payments.router, prefix="/api/v1", tags=["Payments"])
    app.include_router(operations.router, prefix="/api/v1", tags=["Operations & Reports"])

    metrics_app = make_asgi_app()
    app.mount("/metrics", metrics_app)

    origins = [origin.strip() for origin in settings.CORS_ORIGINS.split(",") if origin.strip()]
    app.add_middleware(
        CORSMiddleware,
        allow_origins=origins,
        allow_credentials=True,
        allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        allow_headers=["*"],
    )

    app.add_middleware(SecurityHeadersMiddleware)
    app.add_middleware(RequestContextMiddleware)

    from app.middleware.body_limit import ContentLengthLimitMiddleware
    app.add_middleware(
        ContentLengthLimitMiddleware,
        max_request_size_bytes=settings.MAX_REQUEST_SIZE_BYTES
    )

    @app.exception_handler(Exception)
    async def global_exception_handler(request: Request, exc: Exception):
        from app.core.metrics_collector import metrics_collector
        metrics_collector.record_5xx_error()
        logger = logging.getLogger("7s.exception")
        logger.exception("Unhandled exception", extra={"request_id": request_id_var.get("")})
        return JSONResponse(
            status_code=500,
            content={"message": "Internal server error"}
        )


    from fastapi.exceptions import RequestValidationError
    @app.exception_handler(RequestValidationError)
    async def validation_exception_handler(request: Request, exc: RequestValidationError):
        # Sanitize output by mapping errors to simple JSON without leaking python types or internal schema classes
        sanitized_errors = []
        for error in exc.errors():
            sanitized_errors.append({
                "field": ".".join(str(loc) for loc in error.get("loc", [])),
                "message": error.get("msg", "Invalid input")
            })
        return JSONResponse(
            status_code=422,
            content={"message": "Validation failed", "errors": sanitized_errors}
        )

    return app

app = create_app()
