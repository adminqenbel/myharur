from datetime import timedelta
from typing import Any, Optional
from fastapi import APIRouter, Body, Depends, HTTPException, Query
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from pydantic import BaseModel

from app.core.security import create_access_token, verify_password
from app.core.config import settings
from app.api import deps
from app.crud import crud_user
from app.schemas.user import Token, UserCreate, UserMe, PasswordChange, PasswordSet, UsernameSet, UsernameCheckResult
from app.models.user import User as UserModel

router = APIRouter()


class GoogleAuthRequest(BaseModel):
    email: str
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    photo_url: Optional[str] = None


from app.core.security import create_access_token, create_refresh_token, verify_password
from app.core.redis_session import create_session, revoke_all_sessions
from app.core.rbac import get_user_permissions
from fastapi import Request

def _make_token_response(user: UserModel, db, request: Request = None) -> dict:
    crud_user.ensure_user_identifiers(db, user)
    crud_user.update_streak(db, user)
    # Update last_login
    from datetime import datetime
    user.last_login = datetime.utcnow()
    db.commit()
    db.refresh(user)
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    token = create_access_token(user.id, expires_delta=access_token_expires)
    refresh_token = create_refresh_token(user.id)
    
    device_info = request.headers.get("User-Agent", "Unknown Device") if request else "Unknown Device"
    
    # Store in Redis
    create_session(user.id, refresh_token, device_info=device_info)
    
    # Hydrate permissions
    user.permissions = get_user_permissions(db, user)
    
    return {
        "access_token": token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "user": user,
    }


@router.post("/login", response_model=Token)
@deps.limiter.limit("5/minute")
def login_access_token(
    request: Request,
    db: Session = Depends(deps.get_db),
    form_data: OAuth2PasswordRequestForm = Depends()
) -> Any:
    try:
        user = crud_user.authenticate(db, email=form_data.username, password=form_data.password)
    except ValueError as e:
        raise HTTPException(status_code=403, detail=str(e))
        
    if not user:
        raise HTTPException(status_code=401, detail="Incorrect email or password")
    if not user.is_active:
        raise HTTPException(status_code=403, detail="Account is inactive")
    if user.is_banned:
        raise HTTPException(status_code=403, detail=f"Account is banned. Reason: {user.ban_reason or 'Policy violation'}")
    return _make_token_response(user, db, request)


@router.post("/register", response_model=Token)
@deps.limiter.limit("3/hour")
def register_user(
    request: Request,
    *,
    db: Session = Depends(deps.get_db),
    user_in: UserCreate,
) -> Any:
    # Check username if provided
    if user_in.username:
        err = crud_user.validate_username(user_in.username)
        if err:
            raise HTTPException(status_code=422, detail=err)
        existing = crud_user.get_user_by_username(db, user_in.username)
        if existing:
            raise HTTPException(status_code=409, detail="Username already taken.")
    if user_in.display_name:
        dn_err = crud_user.validate_display_name(user_in.display_name)
        if dn_err:
            raise HTTPException(status_code=422, detail=dn_err)

    user = crud_user.get_user_by_email(db, email=user_in.email)
    if user:
        raise HTTPException(status_code=409, detail="Email already registered.")
    user = crud_user.create_user(db, user_in=user_in)
    return _make_token_response(user, db, request)


@router.post("/google", response_model=Token)
@deps.limiter.limit("5/minute")
def google_auth(
    request: Request,
    *,
    db: Session = Depends(deps.get_db),
    req: GoogleAuthRequest,
) -> Any:
    user = crud_user.create_or_link_google_user(
        db,
        email=req.email,
        first_name=req.first_name or "User",
        last_name=req.last_name or "",
        photo_url=req.photo_url or "",
    )
    return _make_token_response(user, db, request)


@router.get("/check-username", response_model=UsernameCheckResult)
def check_username(
    username: str = Query(..., min_length=3, max_length=30),
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    """Check if a username is available and valid."""
    available, err = crud_user.is_username_available(db, username, exclude_user_id=current_user.id)
    return {"username": username.lower(), "available": available, "error": err}


@router.post("/set-username", response_model=Token)
def set_username(
    *,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
    payload: UsernameSet,
) -> Any:
    """Set username for users who don't have one yet."""
    if current_user.username and not current_user.username_required:
        raise HTTPException(status_code=400, detail="Username already set. Use update-profile to change display name.")

    user, err = crud_user.set_username(
        db,
        current_user,
        payload.username,
        display_name=payload.display_name,
    )
    if err:
        raise HTTPException(status_code=422, detail=err)

    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    token = create_access_token(user.id, expires_delta=access_token_expires)
    return {
        "access_token": token,
        "token_type": "bearer",
        "user": user,
    }


@router.post("/change-password")
def change_password(
    *,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
    password_in: PasswordChange,
) -> Any:
    if not verify_password(password_in.old_password, current_user.hashed_password):
        raise HTTPException(status_code=400, detail="Incorrect current password")
    crud_user.update_password(db, current_user, password_in.new_password)
    return {"message": "Password updated successfully"}


@router.post("/set-password")
def set_password(
    *,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
    password_in: PasswordSet,
) -> Any:
    """For Google-only accounts to set a first password."""
    if current_user.login_provider not in ("google",):
        raise HTTPException(status_code=400, detail="Use change-password for existing password accounts")
    crud_user.update_password(db, current_user, password_in.new_password)
    return {"message": "Password set successfully"}

@router.post("/logout-all")
def logout_all_devices(
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    """Revokes all active sessions for the current user."""
    revoke_all_sessions(current_user.id)
    return {"message": "All devices have been logged out successfully."}
