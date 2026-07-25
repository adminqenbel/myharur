from typing import Any, List
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api import deps
from app.crud import crud_user
from app.schemas.user import User, Profile, ProfileUpdate
from app.models.user import User as UserModel

router = APIRouter()

@router.get("/me", response_model=User)
def read_user_me(
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    """
    Get current user.
    """
    return current_user

@router.put("/me/profile", response_model=Profile)
def update_user_profile(
    *,
    db: Session = Depends(deps.get_db),
    profile_in: ProfileUpdate,
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    """
    Update own profile.
    """
    profile = current_user.profile
    update_data = profile_in.dict(exclude_unset=True)
    for field in update_data:
        setattr(profile, field, update_data[field])
    db.add(profile)
    db.commit()
    db.refresh(profile)
    return profile
