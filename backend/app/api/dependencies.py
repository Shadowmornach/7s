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
from app.services.bambastack_client import bambastack_client

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
        bambastack_client=bambastack_client,
        pubsub_service=_pubsub_instance
    )

def get_operations_service() -> OperationsService:
    return OperationsService(
        operations_repo=operations_repository
    )

async def get_current_user(token: str = Depends(oauth2_scheme)) -> TokenPayload:
    try:
        from app.core.jwt_auth import verify_auth_token
        
        token_data = verify_auth_token(token)
        user_id = token_data["sub"]
        provider = token_data["provider"]
        
        if provider == "supabase":
            user_repo = UserRepository()
            user = await user_repo.get_user_by_id(UUID(user_id))
            if not user:
                raise RuleViolationError("User not found.")
            
            authoritative_role = user.get("role", "PASSENGER")
            return TokenPayload(sub=user_id, role=authoritative_role)
        else:
            role = token_data.get("role")
            if not role:
                raise RuleViolationError("Invalid legacy token payload.")
            return TokenPayload(sub=user_id, role=role)
            
    except RuleViolationError as e:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=str(e))
    except ValueError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid subject format.")

get_current_user_payload = get_current_user


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
