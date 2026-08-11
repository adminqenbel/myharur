from datetime import datetime, timezone
from app.realtime.server import sio
from app.auth.jwt import verify_access_token
from app.services.mmid import resolve_mmid

@sio.event
async def connect(sid, environ, auth):
    token = (auth or {}).get("token", "")
    if not token:
        raise ConnectionRefusedError("Missing authentication token")
    
    try:
        payload = verify_access_token(token)
    except ValueError as e:
        raise ConnectionRefusedError(f"Invalid token: {e}")
    
    qenbel_id = payload["sub"]
    
    try:
        mmid = await resolve_mmid(qenbel_id, getattr(sio.manager, "redis", None))
    except Exception:
        raise ConnectionRefusedError("Account not provisioned")
    
    redis = getattr(sio.manager, "redis", None)
    if redis:
        await redis.hset(f"socket:{sid}", mapping={
            "mmid": mmid,
            "qenbel_id": qenbel_id,
            "connected_at": datetime.now(timezone.utc).isoformat()
        })
        await redis.expire(f"socket:{sid}", 7200)
        await redis.sadd(f"user_sockets:{mmid}", sid)
        await redis.expire(f"user_sockets:{mmid}", 7200)
    
    await sio.emit("connected", {"mmid": mmid}, to=sid)

@sio.event
async def disconnect(sid):
    redis = getattr(sio.manager, "redis", None)
    if redis:
        session = await redis.hgetall(f"socket:{sid}")
        if session:
            mmid = session.get("mmid")
            if mmid:
                await redis.srem(f"user_sockets:{mmid}", sid)
                remaining = await redis.scard(f"user_sockets:{mmid}")
                if remaining == 0:
                    await sio.emit("user_offline", {"mmid": mmid})
        await redis.delete(f"socket:{sid}")
