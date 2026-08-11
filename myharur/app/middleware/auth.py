from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import JSONResponse
from jose import jwt, JWTError
from sqlalchemy import text
from app.config import get_settings

settings = get_settings()

EXEMPT_PATHS = {"/health", "/docs", "/openapi.json", "/redoc", "/api/v1/auth/provision"}

class JWTAuthMiddleware(BaseHTTPMiddleware):
    """Verifies RS256 token using PUBLIC KEY ONLY. Can NEVER sign tokens."""
    async def dispatch(self, request: Request, call_next):
        if request.url.path in EXEMPT_PATHS or not request.url.path.startswith("/api/"):
            return await call_next(request)
        
        auth = request.headers.get("Authorization", "")
        token = auth.removeprefix("Bearer ").strip()
        
        if not token:
            return JSONResponse({"error": "Missing token"}, status_code=401)
        
        try:
            pub_key = settings.jwt_public_key_pem.replace("\\n", "\n")
            payload = jwt.decode(
                token,
                pub_key,
                algorithms=["RS256"]
            )
            if payload.get("type") != "access":
                raise ValueError("Invalid token type")
            if payload.get("iss") != "qenbel-identity":
                raise ValueError("Invalid issuer")
        except (JWTError, ValueError) as e:
            return JSONResponse({"error": f"Invalid token: {e}"}, status_code=401)
        
        request.state.qenbel_id = payload["sub"]
        request.state.email = payload.get("email", "")
        return await call_next(request)


class MMIDResolutionMiddleware(BaseHTTPMiddleware):
    """
    Resolves qenbel_id -> mmid for every authenticated request.
    Redis cache: 5-minute TTL.
    """
    async def dispatch(self, request: Request, call_next):
        if request.url.path in EXEMPT_PATHS or not hasattr(request.state, "qenbel_id"):
            return await call_next(request)
        
        qenbel_id = request.state.qenbel_id
        redis = getattr(request.app.state, "redis", None)
        mmid = None
        
        if redis:
            try:
                mmid = await redis.get(f"mmid:{qenbel_id}")
            except Exception:
                mmid = None
        
        if not mmid:
            from app.db.session import AsyncSessionLocal
            async with AsyncSessionLocal() as db:
                result = await db.execute(
                    text("SELECT mmid FROM myharur.accounts WHERE qenbel_id = :qid AND status = 'active'"),
                    {"qid": qenbel_id}
                )
                row = result.fetchone()
                if row:
                    mmid = str(row[0])
            
            if not mmid:
                return JSONResponse(
                    {"error": "MyHarur account not provisioned"},
                    status_code=403
                )
            
            if redis and mmid:
                try:
                    await redis.setex(f"mmid:{qenbel_id}", 300, mmid)
                except Exception:
                    pass
        
        request.state.mmid = mmid
        return await call_next(request)
