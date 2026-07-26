from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel

from app.api import deps
from app.schemas.user import AdminUserList
from app.models.user import User as UserModel, Role as RoleModel

router = APIRouter()


class RoleAssign(BaseModel):
    role_name: str  # "User", "Moderator", "Admin", "Super Admin"


def _require_admin(current_user: UserModel = Depends(deps.get_current_user)) -> UserModel:
    role = getattr(current_user.role, "name", None)
    if role not in ("Admin", "Super Admin"):
        raise HTTPException(status_code=403, detail="Admins only")
    return current_user


def _require_superadmin(current_user: UserModel = Depends(deps.get_current_user)) -> UserModel:
    role = getattr(current_user.role, "name", None)
    if role != "Super Admin":
        raise HTTPException(status_code=403, detail="Super Admins only")
    return current_user


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
