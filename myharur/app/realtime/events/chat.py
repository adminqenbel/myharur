import bleach
import asyncio
from uuid import uuid4
from datetime import datetime, timezone
from app.realtime.server import sio
from app.middleware.rate_limit import check_rate_limit

async def get_socket_session(sid) -> dict:
    redis = getattr(sio.manager, "redis", None)
    if not redis:
        return {}
    session = await redis.hgetall(f"socket:{sid}")
    if not session:
        raise ValueError("Session not found")
    return session

@sio.on("join_room")
async def on_join_room(sid, data):
    try:
        session = await get_socket_session(sid)
    except ValueError:
        await sio.emit("error", {"code": 401, "message": "Not authenticated"}, to=sid)
        return
    
    room_id = str(data.get("room_id", ""))
    await sio.enter_room(sid, f"room:{room_id}")
    await sio.emit("joined_room", {"room_id": room_id}, to=sid)

@sio.on("send_message")
async def on_send_message(sid, data):
    try:
        session = await get_socket_session(sid)
    except ValueError:
        return
    
    mmid = session.get("mmid", "anonymous")
    redis = getattr(sio.manager, "redis", None)
    
    allowed = await check_rate_limit(redis, f"messaging:{mmid}", 60, 60)
    if not allowed:
        await sio.emit("error", {"code": 429, "message": "Slow down"}, to=sid)
        return
    
    room_id = str(data.get("room_id", ""))
    content = str(data.get("content", "")).strip()
    
    if not content or len(content) > 2000:
        await sio.emit("error", {"code": 400, "message": "Invalid message length"}, to=sid)
        return
    
    clean_content = bleach.clean(content, tags=[], strip=True)
    
    message = {
        "id": str(uuid4()),
        "room_id": room_id,
        "sender_mmid": mmid,
        "content": clean_content,
        "timestamp": datetime.now(timezone.utc).isoformat()
    }
    
    await sio.emit("new_message", message, room=f"room:{room_id}")
