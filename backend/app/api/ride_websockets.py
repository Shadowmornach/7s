from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends, Query, HTTPException, status
from uuid import UUID
from app.api.dependencies import get_pubsub_service, get_current_user, get_ride_service
from app.domain.pubsub import PubSubInterface
from app.services.ride_service import RideService
from app.domain.exceptions import DomainException
from app.core.metrics import active_websockets
from app.schemas.auth import TokenPayload

router = APIRouter(prefix="/ws", tags=["WebSockets"])

@router.websocket("/rides/{ride_id}")
async def websocket_ride_endpoint(
    websocket: WebSocket,
    ride_id: UUID,
    token: str = Query(..., description="JWT token for authentication"),
    pubsub_service: PubSubInterface = Depends(get_pubsub_service),
    ride_service: RideService = Depends(get_ride_service)
):
    try:
        # Manually invoke dependency since WebSockets don't auto-resolve Depends in the same way for auth headers sometimes,
        # but here we pass token via Query parameter for simplicity in WS connections.
        user: TokenPayload = await get_current_user(token)
        
        # Enforce IDOR protection: User must have access to the ride
        await ride_service.get_ride(ride_id, user_id=UUID(user.sub), role=user.role)
        
    except (HTTPException, DomainException):
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return

    await websocket.accept()
    active_websockets.inc()
    
    channel = f"ride_{ride_id}"
    
    try:
        async for message in pubsub_service.subscribe(channel):
            await websocket.send_json(message)
    except WebSocketDisconnect:
        pass
    finally:
        active_websockets.dec()
