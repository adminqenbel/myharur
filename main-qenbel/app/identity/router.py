import secrets
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.db.session import get_db
from app.auth.google import get_authorization_url, exchange_code
from app.identity.service import find_or_create_account, create_session, provision_product
from app.auth.jwt import verify_access_token, hash_refresh_token
from app.db.models import Session as SessionModel, Account
from app.identity.schemas import ProvisionRequest

router = APIRouter()

def get_redis(request: Request):
    return getattr(request.app.state, "redis", None)

@router.post("/auth/google")
async def start_google_auth(request: Request):
    redis = get_redis(request)
    state = secrets.token_urlsafe(32)
    url = await get_authorization_url(state, redis)
    return {"authorization_url": url, "state": state}

@router.get("/auth/callback")
async def google_callback(
    code: str,
    state: str,
    request: Request,
    db: AsyncSession = Depends(get_db)
):
    redis = get_redis(request)
    try:
        google_user = await exchange_code(code, state, redis)
        account = await find_or_create_account(google_user, db)
        access_token, refresh_token = await create_session(
            account.qenbel_id, db,
            user_agent=request.headers.get("user-agent"),
            ip=request.client.host if request.client else None
        )
    except ValueError as e:
        raise HTTPException(400, str(e))
    
    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "Bearer",
        "expires_in": 900,
        "qenbel_id": str(account.qenbel_id)
    }

@router.post("/auth/refresh")
async def refresh_token(
    body: dict,
    db: AsyncSession = Depends(get_db)
):
    raw_token = body.get("refresh_token")
    if not raw_token:
        raise HTTPException(400, "refresh_token required")
    
    token_hash = hash_refresh_token(raw_token)
    result = await db.execute(
        select(SessionModel).where(
            SessionModel.refresh_token_hash == token_hash,
            SessionModel.revoked == False
        )
    )
    session = result.scalar_one_or_none()
    
    if not session:
        raise HTTPException(401, "Invalid refresh token")
    if session.expires_at.replace(tzinfo=timezone.utc) < datetime.now(timezone.utc):
        raise HTTPException(401, "Refresh token expired")
    
    session.revoked = True
    await db.flush()
    
    access_token, new_refresh = await create_session(session.qenbel_id, db)
    await db.commit()
    
    return {
        "access_token": access_token,
        "refresh_token": new_refresh,
        "token_type": "Bearer",
        "expires_in": 900
    }

@router.post("/auth/revoke")
async def revoke_session(
    body: dict,
    request: Request,
    db: AsyncSession = Depends(get_db)
):
    auth_header = request.headers.get("Authorization", "")
    token = auth_header.removeprefix("Bearer ").strip()
    
    try:
        payload = verify_access_token(token)
    except ValueError:
        raise HTTPException(401, "Invalid access token")
    
    raw_refresh = body.get("refresh_token", "")
    token_hash = hash_refresh_token(raw_refresh)
    
    result = await db.execute(
        select(SessionModel).where(
            SessionModel.refresh_token_hash == token_hash,
            SessionModel.qenbel_id == payload["sub"]
        )
    )
    session = result.scalar_one_or_none()
    if session:
        session.revoked = True
        await db.commit()
    
    return {"success": True}

@router.get("/identity/me")
async def get_identity(request: Request, db: AsyncSession = Depends(get_db)):
    auth_header = request.headers.get("Authorization", "")
    token = auth_header.removeprefix("Bearer ").strip()
    
    try:
        payload = verify_access_token(token)
    except ValueError:
        raise HTTPException(401, "Invalid or expired token")
    
    account = await db.get(Account, payload["sub"])
    if not account or account.status != "active":
        raise HTTPException(403, "Account not active")
    
    return {
        "qenbel_id": str(account.qenbel_id),
        "email": account.email_normalized,
        "display_name": account.display_name,
        "avatar_url": account.avatar_url,
        "status": account.status
    }

@router.post("/provision")
async def provision_product_endpoint(
    req: ProvisionRequest,
    request: Request,
    db: AsyncSession = Depends(get_db)
):
    auth_header = request.headers.get("Authorization", "")
    token = auth_header.removeprefix("Bearer ").strip()
    
    try:
        payload = verify_access_token(token)
    except ValueError:
        raise HTTPException(401, "Invalid or expired token")
    
    try:
        result = await provision_product(payload["sub"], req.product_slug, db)
    except ValueError as e:
        raise HTTPException(404, str(e))
    
    return result
