from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.api import deps
from app.crud import crud_user
from app.schemas.user import UserMe, Profile, ProfileUpdate, SetupProfile, UserSearchResult
from app.models.user import User as UserModel, Profile as ProfileModel

router = APIRouter()


def _is_admin(user: UserModel) -> bool:
    return getattr(user.role, "name", None) in ("Admin", "Super Admin")


@router.get("/me", response_model=UserMe)
def read_user_me(
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    crud_user.ensure_user_identifiers(db, current_user)
    return current_user


@router.put("/me/profile", response_model=Profile)
def update_user_profile(
    *,
    db: Session = Depends(deps.get_db),
    profile_in: ProfileUpdate,
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    profile = current_user.profile
    if not profile:
        profile = ProfileModel(user_id=current_user.id)
        db.add(profile)
        db.flush()

    update_data = profile_in.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        if field in ("first_name", "last_name", "bio") and value:
            for check_field in (field,):
                text_val = str(value)
                err = crud_user.validate_display_name(text_val) if field == "bio" else None
                if field in ("first_name", "last_name"):
                    for word in crud_user.ABUSIVE_WORDS:
                        if word in text_val.lower():
                            raise HTTPException(status_code=422, detail=f"{field.replace('_', ' ').title()} contains inappropriate language.")
                elif err:
                    raise HTTPException(status_code=422, detail=err)
        setattr(profile, field, value)

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
    err = crud_user.validate_display_name(display_name)
    if err:
        raise HTTPException(status_code=422, detail=err)
    current_user.display_name = display_name.strip()[:60]
    db.commit()
    return {"message": "Display name updated", "display_name": current_user.display_name}


@router.post("/me/setup", response_model=UserMe)
def complete_setup(
    *,
    db: Session = Depends(deps.get_db),
    setup_in: SetupProfile,
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    """Complete the first-time onboarding."""
    try:
        user = crud_user.complete_setup(db, current_user, setup_in)
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))
    return user


@router.get("/search", response_model=List[UserSearchResult])
def search_users(
    q: str = Query(..., min_length=2),
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    """Search users by username, MID, or display name (email for admins only)."""
    results = crud_user.search_users(
        db,
        q,
        include_email=_is_admin(current_user),
    )
    out = []
    for u in results:
        out.append({
            "id": u.id,
            "mid": u.mid,
            "username": u.username,
            "display_name": u.display_name,
            "avatar_url": u.profile.avatar_url if u.profile else None,
            "role": u.role,
        })
    return out
