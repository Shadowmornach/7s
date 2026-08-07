from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends, HTTPException, status
from typing import Dict, List, Set
from uuid import UUID
from datetime import datetime, timezone

from app.api.dependencies import get_pubsub_service, get_current_user, get_ride_service
from app.domain.pubsub import PubSubInterface
from app.services.ride_service import RideService
from app.domain.exceptions import DomainException
from app.core.metrics import active_websockets
from app.schemas.auth import TokenPayload

router = APIRouter(prefix="/ws", tags=["WebSockets"])

user_connections: Dict[str, Set[WebSocket]] = {}
ip_connection_attempts: Dict[str, List[datetime]] = {}

def check_ip_rate_limit(ip: str):
    now = datetime.now(timezone.utc)
    attempts = ip_connection_attempts.get(ip, [])
    attempts = [t for t in attempts if (now - t).total_seconds() < 60]
    if len(attempts) >= 30:
        raise HTTPException(status_code=status.HTTP_429_TOO_MANY_REQUESTS)
    attempts.append(now)
    ip_connection_attempts[ip] = attempts

@router.websocket("/rides/{ride_id}")
async def websocket_ride_endpoint(
    websocket: WebSocket,
    ride_id: UUID,
    pubsub_service: PubSubInterface = Depends(get_pubsub_service),
    ride_service: RideService = Depends(get_ride_service)
):
    client_ip = websocket.client.host if websocket.client else "unknown"
    user_id_str = None
    
    try:
        check_ip_rate_limit(client_ip)
        
        protocols = websocket.headers.get("sec-websocket-protocol", "").split(",")
        token = protocols[0].strip() if protocols else None
                
        if not token:
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
            return

        user: TokenPayload = await get_current_user(token)
        user_id_str = str(user.sub)
        
        if user_id_str not in user_connections:
            user_connections[user_id_str] = set()
            
        if len(user_connections[user_id_str]) >= 3:
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
            return
            
        await ride_service.get_ride(ride_id, user_id=UUID(user.sub), role=user.role)
        
        await websocket.accept(subprotocol=token)
        user_connections[user_id_str].add(websocket)
        active_websockets.inc()
        
    except (HTTPException, DomainException, ValueError):
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return

    channel = f"ride_{ride_id}"
    try:
        async for message in pubsub_service.subscribe(channel):
            await websocket.send_json(message)
    except WebSocketDisconnect:
        pass
    finally:
        active_websockets.dec()
        if user_id_str and user_id_str in user_connections and websocket in user_connections[user_id_str]:
            user_connections[user_id_str].remove(websocket)
