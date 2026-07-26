from datetime import timedelta
from typing import Any, Optional
from fastapi import APIRouter, Body, Depends, HTTPException
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from pydantic import BaseModel

from app.core.security import create_access_token, verify_password
from app.core.config import settings
from app.api import deps
from app.crud import crud_user
from app.schemas.user import Token, UserCreate, User, PasswordChange, PasswordSet
from app.models.user import User as UserModel

router = APIRouter()


class GoogleAuthRequest(BaseModel):
    email: str
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    photo_url: Optional[str] = None


def _make_token_response(user: UserModel, db) -> dict:
    from app.schemas.user import User as UserSchema
    crud_user.update_streak(db, user)
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    token = create_access_token(user.id, expires_delta=access_token_expires)
    return {
        "access_token": token,
        "token_type": "bearer",
        "user": user,
    }


@router.post("/login", response_model=Token)
def login_access_token(
    db: Session = Depends(deps.get_db),
    form_data: OAuth2PasswordRequestForm = Depends()
) -> Any:
    user = crud_user.authenticate(db, email=form_data.username, password=form_data.password)
    if not user:
        raise HTTPException(status_code=400, detail="Incorrect email or password")
    if not user.is_active:
        raise HTTPException(status_code=400, detail="Inactive user")
    return _make_token_response(user, db)


@router.post("/register", response_model=Token)
def register_user(
    *,
    db: Session = Depends(deps.get_db),
    user_in: UserCreate,
) -> Any:
    user = crud_user.get_user_by_email(db, email=user_in.email)
    if user:
        raise HTTPException(status_code=400, detail="Email already registered.")
    user = crud_user.create_user(db, user_in=user_in)
    return _make_token_response(user, db)


@router.post("/google", response_model=Token)
def google_auth(
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
    return _make_token_response(user, db)


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
