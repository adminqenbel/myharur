from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from datetime import datetime

from app.api import deps
from app.schemas.user import AdminUserList
from app.models.user import User as UserModel, Role as RoleModel, Profile as ProfileModel
from app.models.news import News as NewsModel

router = APIRouter()


class RoleAssign(BaseModel):
    role_name: str  # "User", "Moderator", "Admin", "Super Admin"


def _require_admin(current_user: UserModel = Depends(deps.get_current_user)) -> UserModel:
    role = getattr(current_user.role, "name", None)
    if role not in ("Admin", "Super Admin"):
        raise HTTPException(status_code=403, detail="Admins only")
    return current_user


def _require_moderator(current_user: UserModel = Depends(deps.get_current_user)) -> UserModel:
    """Require at least Moderator role."""
    role = getattr(current_user.role, "name", None)
    if role not in ("Moderator", "Admin", "Super Admin"):
        raise HTTPException(status_code=403, detail="Moderators/Admins only")
    return current_user


def _require_superadmin(current_user: UserModel = Depends(deps.get_current_user)) -> UserModel:
    role = getattr(current_user.role, "name", None)
    if role != "Super Admin":
        raise HTTPException(status_code=403, detail="Super Admins only")
    return current_user


# ── User Management ──────────────────────────────────────────────────────────

@router.get("/users", response_model=List[AdminUserList])
def list_all_users(
    db: Session = Depends(deps.get_db),
    skip: int = 0,
    limit: int = 50,
    current_user: UserModel = Depends(_require_admin),
) -> Any:
    users = db.query(UserModel).offset(skip).limit(limit).all()
    return users


@router.put("/users/{user_id}/role")
def assign_role(
    user_id: int,
    role_in: RoleAssign,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(_require_admin),
) -> Any:
    user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Only Super Admins can assign Admin/Super Admin roles
    if role_in.role_name in ("Admin", "Super Admin"):
        if current_user.role.name != "Super Admin":
            raise HTTPException(status_code=403, detail="Only Super Admins can assign admin roles")

    role = db.query(RoleModel).filter(RoleModel.name == role_in.role_name).first()
    if not role:
        role = RoleModel(name=role_in.role_name)
        db.add(role)
        db.commit()
        db.refresh(role)

    user.role_id = role.id
    db.commit()
    return {"message": f"Role '{role_in.role_name}' assigned to user {user_id}"}


@router.put("/users/{user_id}/toggle-active")
def toggle_user_active(
    user_id: int,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(_require_admin),
) -> Any:
    user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.is_active = not user.is_active
    db.commit()
    return {"message": "User status updated", "is_active": user.is_active}


# ── News Moderation ──────────────────────────────────────────────────────────

def _get_author_name(db: Session, user_id: int) -> str:
    profile = db.query(ProfileModel).filter(ProfileModel.user_id == user_id).first()
    if profile:
        name = f"{profile.first_name or ''} {profile.last_name or ''}".strip()
        return name or "Anonymous"
    return "Anonymous"


@router.get("/news/pending")
def list_pending_news(
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(_require_moderator),
) -> Any:
    """List all news awaiting approval."""
    pending = (
        db.query(NewsModel)
        .filter(NewsModel.is_approved == False)
        .order_by(NewsModel.created_at.desc())
        .all()
    )
    return [
        {
            "id": n.id,
            "title": n.title,
            "description": n.description,
            "image_url": n.image_url,
            "created_at": n.created_at.isoformat() if n.created_at else None,
            "author_name": _get_author_name(db, n.author_id),
            "is_approved": n.is_approved,
        }
        for n in pending
    ]


@router.put("/news/{news_id}/approve")
def approve_news(
    news_id: int,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(_require_moderator),
) -> Any:
    """Approve a pending news post."""
    news = db.query(NewsModel).filter(NewsModel.id == news_id).first()
    if not news:
        raise HTTPException(status_code=404, detail="News not found")

    news.is_approved = True
    news.verified_by = current_user.id
    news.verified_at = datetime.utcnow()
    db.commit()
    return {"message": "News approved", "id": news_id}


@router.put("/news/{news_id}/reject")
def reject_news(
    news_id: int,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(_require_moderator),
) -> Any:
    """Reject and delete a pending news post."""
    news = db.query(NewsModel).filter(NewsModel.id == news_id).first()
    if not news:
        raise HTTPException(status_code=404, detail="News not found")

    db.delete(news)
    db.commit()
    return {"message": "News rejected and removed", "id": news_id}
