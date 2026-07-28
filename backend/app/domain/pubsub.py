from abc import ABC, abstractmethod
import typing

class PubSubInterface(ABC):
    @abstractmethod
    async def subscribe(self, channel: str) -> typing.AsyncGenerator[dict, None]:
        pass

    @abstractmethod
    async def publish(self, channel: str, message: dict) -> None:
        pass
