from datetime import timedelta
from typing import Any
from fastapi import APIRouter, Body, Depends, HTTPException
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from pydantic import BaseModel

class GoogleAuthRequest(BaseModel):
    email: str
    first_name: str | None = None
    last_name: str | None = None
    photo_url: str | None = None

from app.core.security import create_access_token
from app.core.config import settings
from app.api import deps
from app.crud import crud_user
from app.schemas.user import Token, UserCreate, User

router = APIRouter()

@router.post("/login", response_model=Token)
def login_access_token(
    db: Session = Depends(deps.get_db), form_data: OAuth2PasswordRequestForm = Depends()
) -> Any:
    """
    OAuth2 compatible token login, get an access token for future requests
    """
    user = crud_user.authenticate(
        db, email=form_data.username, password=form_data.password
    )
    if not user:
        raise HTTPException(status_code=400, detail="Incorrect email or password")
    elif not user.is_active:
        raise HTTPException(status_code=400, detail="Inactive user")
    
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    return {
        "access_token": create_access_token(
            user.id, expires_delta=access_token_expires
        ),
        "token_type": "bearer",
    }

@router.post("/register", response_model=User)
def register_user(
    *,
    db: Session = Depends(deps.get_db),
    user_in: UserCreate,
) -> Any:
    """
    Register new user.
    """
    user = crud_user.get_user_by_email(db, email=user_in.email)
    if user:
        raise HTTPException(
            status_code=400,
            detail="The user with this email already exists in the system.",
        )
    user = crud_user.create_user(db, user_in=user_in)
    return user

@router.post("/google", response_model=Token)
def google_auth(
    *,
    db: Session = Depends(deps.get_db),
    req: GoogleAuthRequest,
) -> Any:
    """
    Authenticate or Register via Google.
    """
    from app.models.user import User as UserModel, Profile as ProfileModel, Role as RoleModel
    import secrets
    
    user = db.query(UserModel).filter(UserModel.email == req.email).first()
    
    if not user:
        # Create user
        user_role = db.query(RoleModel).filter(RoleModel.name == "User").first()
        if not user_role:
            user_role = RoleModel(name="User")
            db.add(user_role)
            db.commit()
            db.refresh(user_role)
            
        from app.core.security import get_password_hash
        hashed_password = get_password_hash(secrets.token_urlsafe(16))
        
        user = UserModel(
            email=req.email,
            hashed_password=hashed_password,
            role_id=user_role.id,
            is_active=True
        )
        db.add(user)
        db.commit()
        db.refresh(user)
        
        profile = ProfileModel(
            user_id=user.id,
            first_name=req.first_name,
            last_name=req.last_name,
            avatar_url=req.photo_url
        )
        db.add(profile)
        db.commit()

    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    return {
        "access_token": create_access_token(
            user.id, expires_delta=access_token_expires
        ),
        "token_type": "bearer",
    }
