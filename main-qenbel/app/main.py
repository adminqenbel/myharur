from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
import redis.asyncio as aioredis
from app.config import get_settings
from app.identity.router import router as identity_router

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
    title="QenBel Identity Service",
    docs_url=None if settings.is_production else "/docs",
    redoc_url=None,
    lifespan=lifespan
)

if settings.is_production:
    app.add_middleware(
        TrustedHostMiddleware,
        allowed_hosts=["main-qenbel.onrender.com", "qenbel-identity.onrender.com", "qenbel.onrender.com"]
    )

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins_list,
    allow_credentials=True,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type"]
)
app.add_middleware(GZipMiddleware, minimum_size=1000)

class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        response = await call_next(request)
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["Referrer-Policy"] = "no-referrer"
        response.headers["Content-Security-Policy"] = "default-src 'none'"
        if settings.is_production:
            response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
        return response

app.add_middleware(SecurityHeadersMiddleware)

app.include_router(identity_router, tags=["Identity"])

@app.get("/health")
async def health():
    return {"status": "ok", "service": "qenbel-identity"}
