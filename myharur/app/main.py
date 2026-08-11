from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
import redis.asyncio as aioredis

from app.config import get_settings
from app.middleware.auth import JWTAuthMiddleware, MMIDResolutionMiddleware
from app.middleware.rate_limit import RateLimitMiddleware

from app.api.v1.auth import router as auth_router
from app.api.v1.emergency import router as emergency_router
from app.api.v1.orders import router as orders_router

settings = get_settings()

@asynccontextmanager
async def lifespan(app: FastAPI):
    try:
        app.state.redis = aioredis.from_url(
            settings.redis_url,
            encoding="utf-8",
            decode_responses=True
        )
    except Exception:
        app.state.redis = None
    yield
    if getattr(app.state, "redis", None):
        await app.state.redis.aclose()

app = FastAPI(
    title="MyHarur Application Service",
    docs_url=None if settings.is_production else "/docs",
    redoc_url=None,
    lifespan=lifespan
)

app.add_middleware(RateLimitMiddleware)
app.add_middleware(MMIDResolutionMiddleware)
app.add_middleware(JWTAuthMiddleware)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins_list,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type"]
)
app.add_middleware(GZipMiddleware, minimum_size=1000)

class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        response = await call_next(request)
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["Referrer-Policy"] = "no-referrer"
        return response

app.add_middleware(SecurityHeadersMiddleware)

app.include_router(auth_router)
app.include_router(emergency_router)
app.include_router(orders_router)

@app.get("/health")
async def health():
    return {"status": "ok", "service": "myharur-app"}
