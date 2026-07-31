import os
import json
import uuid
import redis
from datetime import timedelta

redis_url = os.getenv("REDIS_URL", "redis://localhost:6379/0")
try:
    redis_client = redis.from_url(redis_url, decode_responses=True)
except Exception:
    redis_client = None

def create_session(user_id: int, refresh_token: str, max_concurrent: int = 5) -> str:
    """Stores session in redis, enforces max concurrent sessions."""
    if not redis_client:
        return str(uuid.uuid4())
    
    session_id = str(uuid.uuid4())
    key = f"user_sessions:{user_id}"
    
    # Get existing sessions
    existing = redis_client.smembers(key)
    if len(existing) >= max_concurrent:
        # Just an example of removing the oldest or random to enforce limit. 
        # In a real system, you'd track timestamps.
        for old_sid in list(existing)[max_concurrent - 1:]:
            redis_client.srem(key, old_sid)
            redis_client.delete(f"session:{old_sid}")
            
    # Add new session
    redis_client.sadd(key, session_id)
    redis_client.setex(
        f"session:{session_id}",
        timedelta(days=7),
        json.dumps({"user_id": user_id, "refresh_token": refresh_token})
    )
    return session_id

def validate_refresh_session(user_id: int, session_id: str, refresh_token: str) -> bool:
    if not redis_client:
        return True
    data = redis_client.get(f"session:{session_id}")
    if not data:
        return False
    parsed = json.loads(data)
    return parsed.get("user_id") == user_id and parsed.get("refresh_token") == refresh_token

def revoke_session(user_id: int, session_id: str):
    if not redis_client:
        return
    redis_client.srem(f"user_sessions:{user_id}", session_id)
    redis_client.delete(f"session:{session_id}")
