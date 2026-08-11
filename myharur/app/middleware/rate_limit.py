import time
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import JSONResponse

RATE_LIMITS = {
    "global_ip":     (200, 60),    # 200 req/min per IP
    "auth":          (10,  60),    # 10 req/min per IP
    "standard":      (60,  60),    # 60 req/min per MMID
    "emergency":     (5,   60),    # 5 req/min per MMID
    "ai":            (20,  60),    # 20 req/min per MMID
    "ai_daily":      (100, 86400), # 100 req/day per MMID (Gemini)
    "upload":        (10,  60),    # 10 req/min per MMID
    "messaging":     (60,  60),    # 60 messages/min per MMID
}

PATH_TIERS = {
    "/api/v1/emergency": "emergency",
    "/api/v1/support":   "ai",
    "/api/v1/upload":    "upload",
}

async def check_rate_limit(redis_client, key: str, limit: int, window: int) -> bool:
    """Sliding window check via Redis."""
    if not redis_client:
        return True
    try:
        now = int(time.time())
        window_key = f"rl:{key}:{now // window}"
        
        pipe = redis_client.pipeline()
        pipe.incr(window_key)
        pipe.expire(window_key, window * 2)
        results = await pipe.execute()
        
        count = results[0]
        return count <= limit
    except Exception:
        return True

class RateLimitMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        redis = getattr(request.app.state, "redis", None)
        ip = request.client.host if request.client else "127.0.0.1"
        path = request.url.path
        
        allowed = await check_rate_limit(redis, f"ip:{ip}", 200, 60)
        if not allowed:
            return JSONResponse(
                {"error": "Rate limit exceeded"},
                status_code=429,
                headers={"Retry-After": "60"}
            )
        
        if hasattr(request.state, "mmid"):
            mmid = request.state.mmid
            tier = "standard"
            for prefix, t in PATH_TIERS.items():
                if path.startswith(prefix):
                    tier = t
                    break
            
            limit, window = RATE_LIMITS[tier]
            allowed = await check_rate_limit(redis, f"{tier}:{mmid}", limit, window)
            if not allowed:
                return JSONResponse(
                    {"error": f"Rate limit exceeded for {tier}"},
                    status_code=429,
                    headers={"Retry-After": str(window)}
                )
        
        return await call_next(request)
