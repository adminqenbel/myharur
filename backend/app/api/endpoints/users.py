from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.api import deps
from app.crud import crud_user
from app.schemas.user import User, Profile, ProfileUpdate, SetupProfile
from app.models.user import User as UserModel

router = APIRouter()


@router.get("/me", response_model=User)
def read_user_me(
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    return current_user


@router.put("/me/profile", response_model=Profile)
def update_user_profile(
    *,
    db: Session = Depends(deps.get_db),
    profile_in: ProfileUpdate,
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    profile = current_user.profile
    update_data = profile_in.dict(exclude_unset=True)
    for field in update_data:
        setattr(profile, field, update_data[field])
    db.add(profile)
    db.commit()
    db.refresh(profile)
    return profile


@router.post("/me/setup", response_model=User)
def complete_setup(
    *,
    db: Session = Depends(deps.get_db),
    setup_in: SetupProfile,
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    """Complete the first-time onboarding."""
    user = crud_user.complete_setup(db, current_user, setup_in)
    return user
