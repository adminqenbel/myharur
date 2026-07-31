from typing import Generator, Optional
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import jwt, JWTError
from sqlalchemy.orm import Session
from pydantic import ValidationError

from app.core.config import settings
from app.db.session import SessionLocal
from app.models.user import User
from app.schemas.user import TokenPayload
from app.crud.crud_user import get_user

from slowapi import Limiter
from slowapi.util import get_remote_address

reusable_oauth2 = OAuth2PasswordBearer(
    tokenUrl=f"{settings.API_V1_STR}/auth/login"
)

limiter = Limiter(key_func=get_remote_address)

def get_db() -> Generator:
    try:
        db = SessionLocal()
        yield db
    finally:
        db.close()

def get_current_user(
    db: Session = Depends(get_db), token: str = Depends(reusable_oauth2)
) -> User:
    try:
        payload = jwt.decode(
            token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM]
        )
        token_data = TokenPayload(**payload)
    except (JWTError, ValidationError):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Could not validate credentials",
        )
    user = get_user(db, user_id=int(token_data.sub))
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if not user.is_active:
        raise HTTPException(status_code=400, detail="Inactive user")
    return user

def get_current_active_superuser(
    current_user: User = Depends(get_current_user),
) -> User:
    if current_user.role.name != "Super Admin":
        raise HTTPException(
            status_code=400, detail="The user doesn't have enough privileges"
        )
    return current_user

# =========================================
# V4 ENTERPRISE RBAC DEPENDENCIES
# =========================================
from app.core.rbac import require_permissions

def check_permissions(*perms: str):
    """
    Factory function to create a dependency that checks for all specified permissions.
    Usage: @router.post("/x", dependencies=[Depends(check_permissions("Write", "Approve"))])
    """
    def _dependency(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
        dep = require_permissions(list(perms))
        return dep(current_user, db)
    return _dependency

def get_optional_current_user(
    db: Session = Depends(get_db),
    token: str = Depends(OAuth2PasswordBearer(tokenUrl=f"/api/v1/auth/login", auto_error=False)),
) -> Optional[User]:
    """Returns user if token valid, else None (for public endpoints)."""
    if not token:
        return None
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        token_data = TokenPayload(**payload)
    except (JWTError, ValidationError):
        return None
    return get_user(db, user_id=int(token_data.sub))
