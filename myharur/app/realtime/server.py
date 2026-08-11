import socketio
from app.config import get_settings

settings = get_settings()

sio = socketio.AsyncServer(
    async_mode="asgi",
    cors_allowed_origins=settings.allowed_origins_list,
    client_manager=socketio.AsyncRedisManager(settings.redis_url),
    logger=False,
    engineio_logger=False
)

socket_app = socketio.ASGIApp(sio)
