import asyncio
import typing
from app.domain.pubsub import PubSubInterface

class InMemoryPubSub(PubSubInterface):
    def __init__(self):
        self.subscribers: dict[str, set[asyncio.Queue]] = {}

    async def subscribe(self, channel: str) -> typing.AsyncGenerator[dict, None]:
        queue = asyncio.Queue()
        if channel not in self.subscribers:
            self.subscribers[channel] = set()
        self.subscribers[channel].add(queue)

        try:
            while True:
                message = await queue.get()
                yield message
        finally:
            self.subscribers[channel].remove(queue)
            if not self.subscribers[channel]:
                del self.subscribers[channel]

    async def publish(self, channel: str, message: dict) -> None:
        if channel in self.subscribers:
            for queue in self.subscribers[channel]:
                await queue.put(message)
