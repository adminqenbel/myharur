from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.api import deps
from app.crud import crud_user
from app.schemas.user import User, Profile, ProfileUpdate, SetupProfile, UserSearchResult
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


@router.put("/me/display-name")
def update_display_name(
    *,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
    display_name: str = Query(..., max_length=60),
) -> Any:
    """Update display name (editable, not unique, max 60 chars)."""
    current_user.display_name = display_name[:60]
    db.commit()
    return {"message": "Display name updated", "display_name": current_user.display_name}


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


@router.get("/search", response_model=List[UserSearchResult])
def search_users(
    q: str = Query(..., min_length=2),
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    """Search users by username, MID, display name, or email."""
    results = crud_user.search_users(db, q)
    # Build response with avatar from profile
    out = []
    for u in results:
        out.append({
            "id": u.id,
            "uid": u.uid,
            "mid": u.mid,
            "username": u.username,
            "display_name": u.display_name,
            "avatar_url": u.profile.avatar_url if u.profile else None,
            "role": u.role,
        })
    return out
