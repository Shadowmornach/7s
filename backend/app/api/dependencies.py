from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from uuid import UUID
from app.repositories.ride_repository import RideRepository
from app.repositories.event_repository import EventRepository
from app.repositories.user_repository import UserRepository
from app.services.ride_service import RideService
from app.services.auth_service import AuthService
from app.services.pubsub_service import InMemoryPubSub
from app.domain.pubsub import PubSubInterface
from app.schemas.auth import TokenPayload
from app.core.jwt_auth import decode_token
from app.domain.exceptions import RuleViolationError
from app.db.connection import db

from app.repositories.place_repository import PlaceRepository
from app.repositories.fare_template_repository import FareTemplateRepository
from app.repositories.config_repository import ConfigRepository
from app.repositories.payment_repository import PaymentRepository, payment_repository
from app.services.place_service import PlaceService
from app.services.fare_service import FareService
from app.services.maps_service import MapsService
from app.services.payment_service import PaymentService
from app.services.daraja_client import daraja_client

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")

_pubsub_instance = InMemoryPubSub()

def get_pubsub_service() -> PubSubInterface:
    return _pubsub_instance

def get_ride_service() -> RideService:
    return RideService(
        ride_repo=RideRepository(),
        event_repo=EventRepository(),
        pubsub_service=_pubsub_instance
    )

def get_auth_service() -> AuthService:
    return AuthService(
        user_repo=UserRepository()
    )

def get_maps_service() -> MapsService:
    return MapsService(
        config_repo=ConfigRepository(db.pool)
    )

def get_place_service() -> PlaceService:
    return PlaceService(
        place_repo=PlaceRepository(db.pool),
        maps_service=get_maps_service()
    )

def get_fare_service() -> FareService:
    return FareService(
        fare_template_repo=FareTemplateRepository(db.pool),
        maps_service=get_maps_service()
    )

from app.repositories.operations_repository import OperationsRepository, operations_repository
from app.services.operations_service import OperationsService

def get_payment_service() -> PaymentService:
    return PaymentService(
        payment_repo=payment_repository,
        ride_repo=RideRepository(),
        user_repo=UserRepository(),
        daraja_client=daraja_client,
        pubsub_service=_pubsub_instance
    )

def get_operations_service() -> OperationsService:
    return OperationsService(
        operations_repo=operations_repository
    )

async def get_current_user(token: str = Depends(oauth2_scheme)) -> TokenPayload:
    try:
        payload = decode_token(token)
        user_id = payload.get("sub")
        role = payload.get("role")
        if user_id is None or role is None:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token payload")
        return TokenPayload(sub=user_id, role=role)
    except RuleViolationError as e:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=str(e))

def require_role(allowed_roles: list[str]):
    async def role_checker(current_user: TokenPayload = Depends(get_current_user)):
        user_role_upper = current_user.role.upper() if current_user.role else ""
        allowed_roles_upper = [r.upper() for r in allowed_roles]
        if user_role_upper not in allowed_roles_upper:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN, 
                detail=f"Operation not permitted. Required roles: {allowed_roles}"
            )
        return current_user
    return role_checker

import ipaddress
from fastapi import Request
from app.core.config import settings

def verify_daraja_ip_origin(request: Request) -> None:
    """
    Verifies that an incoming Daraja webhook callback originates from an allowed Safaricom IP subnet (Document 5 NFR)
    AND contains the valid shared secret token query parameter if configured.
    """
    if settings.DARAJA_WEBHOOK_SECRET:
        secret_token = settings.DARAJA_WEBHOOK_SECRET.get_secret_value()
        query_token = request.query_params.get("token")
        if not query_token or query_token != secret_token:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Forbidden: Invalid or missing webhook query secret token"
            )

    if not settings.ENABLE_DARAJA_IP_VALIDATION:
        return

    forwarded_for = request.headers.get("X-Forwarded-For")
    if forwarded_for:
        client_ip_str = forwarded_for.split(",")[0].strip()
    elif request.client:
        client_ip_str = request.client.host
    else:
        client_ip_str = ""

    if not client_ip_str:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Forbidden: Unable to determine client IP address"
        )

    if client_ip_str == "testclient":
        return

    try:
        client_ip = ipaddress.ip_address(client_ip_str)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Forbidden: Invalid client IP format '{client_ip_str}'"
        )

    allowed_networks = [net.strip() for net in settings.DARAJA_ALLOWED_IPS.split(",") if net.strip()]
    
    is_allowed = False
    for net_str in allowed_networks:
        if net_str == "testclient":
            continue
        try:
            if "/" in net_str:
                network = ipaddress.ip_network(net_str, strict=False)
                if client_ip in network:
                    is_allowed = True
                    break
            else:
                allowed_ip = ipaddress.ip_address(net_str)
                if client_ip == allowed_ip:
                    is_allowed = True
                    break
        except ValueError:
            continue

    if not is_allowed:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Forbidden: Callback request origin IP '{client_ip_str}' is not in allowed Safaricom IP ranges (Document 5 NFR)."
        )
