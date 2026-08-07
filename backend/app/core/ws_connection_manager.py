import asyncio
from typing import Dict

class WSConnectionManager:
    def __init__(self, max_per_user: int = 3, max_attempts_per_ip: int = 30, limit_period: int = 60):
        self.max_per_user = max_per_user
        self.max_attempts_per_ip = max_attempts_per_ip
        self.limit_period = limit_period
        
        # user_id -> number of active connections
        self.active_connections: Dict[str, int] = {}
        self.lock = asyncio.Lock()
        
        # IP rate limiting
        self.ip_attempts: Dict[str, list[float]] = {}
        
    async def check_ip_rate_limit(self, ip: str) -> bool:
        import time
        now = time.time()
        async with self.lock:
            if ip in self.ip_attempts:
                self.ip_attempts[ip] = [t for t in self.ip_attempts[ip] if now - t < self.limit_period]
            else:
                self.ip_attempts[ip] = []
                
            if len(self.ip_attempts[ip]) >= self.max_attempts_per_ip:
                return False
                
            self.ip_attempts[ip].append(now)
            return True

    async def connect(self, user_id: str) -> bool:
        async with self.lock:
            current = self.active_connections.get(user_id, 0)
            if current >= self.max_per_user:
                return False
            self.active_connections[user_id] = current + 1
            return True
            
    async def disconnect(self, user_id: str):
        async with self.lock:
            if user_id in self.active_connections:
                self.active_connections[user_id] -= 1
                if self.active_connections[user_id] <= 0:
                    del self.active_connections[user_id]

ws_manager = WSConnectionManager()
