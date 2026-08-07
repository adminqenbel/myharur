from typing import Any, List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session
from sqlalchemy import func
from pydantic import BaseModel
from datetime import datetime
import csv
import io

from app.api import deps
from app.schemas.user import AdminUserList
from app.models.user import User as UserModel, Role as RoleModel, Profile as ProfileModel
from app.models.news import News as NewsModel

router = APIRouter()


class RoleAssign(BaseModel):
    role_name: str  # "User", "Moderator", "Admin", "Super Admin"


class BanUser(BaseModel):
    reason: Optional[str] = None


from app.core.rbac import promote_to_admin, demote_from_admin
from app.api.deps import check_permissions

# ── User Management ──────────────────────────────────────────────────────────

@router.get("/users", response_model=List[AdminUserList])
def list_all_users(
    db: Session = Depends(deps.get_db),
    skip: int = 0,
    limit: int = 50,
    q: Optional[str] = Query(None, description="Search by username, MID, email, display name"),
    role: Optional[str] = Query(None, description="Filter by role"),
    status: Optional[str] = Query(None, description="Filter by status (active/banned)"),
    current_user: UserModel = Depends(check_permissions("Manage Roles")),
) -> Any:
    query = db.query(UserModel)
    if q:
        pattern = f"%{q}%"
        query = query.filter(
            (func.lower(UserModel.username).like(q.lower())) |
            (UserModel.mid == q) |
            (UserModel.mid.like(f"{q}%")) |
            (func.lower(UserModel.display_name).like(pattern.lower())) |
            (func.lower(UserModel.email).like(pattern.lower())) |
            (UserModel.uid == q)
        )
    if role:
        query = query.join(UserModel.roles).filter(RoleModel.name == role)
    if status:
        if status.lower() == "active":
            query = query.filter(UserModel.is_active == True)
        elif status.lower() == "banned":
            query = query.filter(UserModel.is_banned == True)

    users = query.offset(skip).limit(limit).all()
    return users


@router.get("/users/export")
def export_users_csv(
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(check_permissions("Manage Roles")),
) -> Any:
    """Export all users as CSV."""
    users = db.query(UserModel).all()
    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(["ID", "MID", "Username", "Display Name", "Email", "Role", "Status", "Banned", "Created At", "Last Login"])
    for u in users:
        writer.writerow([
            u.id,
            u.mid or "",
            u.username or "",
            u.display_name or "",
            u.email,
            u.role.name if u.role else "",
            "Active" if u.is_active else "Inactive",
            "Yes" if u.is_banned else "No",
            u.created_at.isoformat() if u.created_at else "",
            u.last_login.isoformat() if u.last_login else "",
        ])
    output.seek(0)
    return StreamingResponse(
        iter([output.getvalue()]),
        media_type="text/csv",
        headers={"Content-Disposition": "attachment; filename=users_export.csv"}
    )


from app.models.admin import AuditLog, DeletionRequest

def log_admin_action(db: Session, admin_id: int, action: str, target_id: Optional[int] = None, details: Optional[dict] = None):
    log = AuditLog(admin_id=admin_id, action=action, target_id=target_id, details=details)
    db.add(log)
    db.commit()

@router.put("/users/{user_id}/role")
def assign_role(
    user_id: int,
    role_in: RoleAssign,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(check_permissions("Manage Roles")),
) -> Any:
    user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Only Super Admins can assign Admin/Super Admin roles
    if role_in.role_name in ("Admin", "Super Admin") and not current_user.role.name == "Super Admin":
        raise HTTPException(status_code=403, detail="Only Super Admins can assign admin roles")

    from app.core.rbac import promote_to_admin
    try:
        promote_to_admin(db, user, role_in.role_name)
    except ValueError as e:
        # Create role if missing
        role = RoleModel(name=role_in.role_name)
        db.add(role)
        db.commit()
        db.refresh(role)
        promote_to_admin(db, user, role_in.role_name)

    log_admin_action(db, current_user.id, "assign_role", target_id=user_id, details={"role": role_in.role_name})
    return {"message": f"Role '{role_in.role_name}' assigned to user {user_id}"}

@router.delete("/users/{user_id}/role/{role_name}")
def remove_role(
    user_id: int,
    role_name: str,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(check_permissions("Manage Roles")),
) -> Any:
    user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    if role_name in ("Admin", "Super Admin") and not current_user.role.name == "Super Admin":
        raise HTTPException(status_code=403, detail="Only Super Admins can remove admin roles")
        
    from app.core.rbac import demote_from_admin
    demote_from_admin(db, user, role_name)
    log_admin_action(db, current_user.id, "remove_role", target_id=user_id, details={"role": role_name})
    return {"message": f"Role '{role_name}' removed from user {user_id}"}



@router.put("/users/{user_id}/toggle-active")
def toggle_user_active(
    user_id: int,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(check_permissions("Suspend")),
) -> Any:
    user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.is_active = not user.is_active
    db.commit()
    log_admin_action(db, current_user.id, "toggle_active", target_id=user_id, details={"is_active": user.is_active})
    return {"message": "User status updated", "is_active": user.is_active}


@router.put("/users/{user_id}/ban")
def ban_user(
    user_id: int,
    ban_in: BanUser,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(check_permissions("Suspend")),
) -> Any:
    """Ban a user account."""
    user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if user.role and user.role.name in ("Admin", "Super Admin") and current_user.role.name != "Super Admin":
        raise HTTPException(status_code=403, detail="Cannot ban admins")
    user.is_banned = True
    user.ban_reason = ban_in.reason
    user.is_active = False
    db.commit()
    log_admin_action(db, current_user.id, "ban_user", target_id=user_id, details={"reason": ban_in.reason})
    return {"message": f"User {user_id} banned", "reason": ban_in.reason}


@router.put("/users/{user_id}/unban")
def unban_user(
    user_id: int,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(check_permissions("Suspend")),
) -> Any:
    """Unban a user account."""
    user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.is_banned = False
    user.ban_reason = None
    user.is_active = True
    db.commit()
    log_admin_action(db, current_user.id, "unban_user", target_id=user_id)
    return {"message": f"User {user_id} unbanned"}


@router.put("/users/{user_id}/reset-password")
def reset_user_password(
    user_id: int,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(check_permissions("Write")),
) -> Any:
    """Reset a user's password to a temporary one."""
    import secrets
    from app.core.security import get_password_hash
    user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    temp_pass = secrets.token_urlsafe(12)
    user.hashed_password = get_password_hash(temp_pass)
    db.commit()
    log_admin_action(db, current_user.id, "reset_password", target_id=user_id)
    return {"message": "Password reset", "temp_password": temp_pass}


@router.post("/users/{user_id}/request-deletion")
def request_user_deletion(
    user_id: int,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(check_permissions("Delete")),
) -> Any:
    """Initiate a graceful deletion request for a user."""
    user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # If Super Admin, bypass the 3-approval rule
    if current_user.role.name == "Super Admin":
        user.is_active = False
        user.email = f"archived_{user.id}_{user.email}"
        user.username = f"archived_{user.id}_{user.username}"
        db.commit()
        log_admin_action(db, current_user.id, "force_delete_user", target_id=user_id)
        return {"message": f"User {user_id} bypassed and gracefully archived by Super Admin."}
        
    req = db.query(DeletionRequest).filter(DeletionRequest.user_id == user_id, DeletionRequest.status == "pending").first()
    if not req:
        req = DeletionRequest(user_id=user_id, approvals=[current_user.id], status="pending")
        db.add(req)
        db.commit()
        log_admin_action(db, current_user.id, "request_delete_user", target_id=user_id)
        return {"message": f"Deletion request initiated. Needs 2 more approvals."}
    else:
        raise HTTPException(status_code=400, detail="Pending request already exists.")

@router.post("/deletion-requests/{request_id}/approve")
def approve_deletion_request(
    request_id: int,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(check_permissions("Delete")),
) -> Any:
    """Approve a pending deletion request."""
    req = db.query(DeletionRequest).filter(DeletionRequest.id == request_id, DeletionRequest.status == "pending").first()
    if not req:
        raise HTTPException(status_code=404, detail="Pending request not found")
        
    approvals = list(req.approvals or [])
    if current_user.id in approvals:
        raise HTTPException(status_code=400, detail="You have already approved this request.")
        
    approvals.append(current_user.id)
    req.approvals = approvals
    
    log_admin_action(db, current_user.id, "approve_deletion", target_id=req.user_id)
    
    if len(approvals) >= 3 or current_user.role.name == "Super Admin":
        req.status = "executed"
        user = db.query(UserModel).filter(UserModel.id == req.user_id).first()
        if user:
            user.is_active = False
            user.email = f"archived_{user.id}_{user.email}"
            user.username = f"archived_{user.id}_{user.username}"
        db.commit()
        return {"message": "Deletion approved and executed."}
        
    db.commit()
    return {"message": f"Approval added. Total approvals: {len(approvals)}/3."}


def _get_author_name(db: Session, user_id: int) -> str:
    profile = db.query(ProfileModel).filter(ProfileModel.user_id == user_id).first()
    if profile:
        name = f"{profile.first_name or ''} {profile.last_name or ''}".strip()
        return name or "Anonymous"
    return "Anonymous"


@router.get("/news/pending")
def list_pending_news(
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(check_permissions("Manage News")),
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
    current_user: UserModel = Depends(check_permissions("Manage News")),
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
    current_user: UserModel = Depends(check_permissions("Manage News")),
) -> Any:
    """Reject and delete a pending news post."""
    news = db.query(NewsModel).filter(NewsModel.id == news_id).first()
    if not news:
        raise HTTPException(status_code=404, detail="News not found")

    db.delete(news)
    db.commit()
    return {"message": "News rejected and removed", "id": news_id}


# ── Stats ─────────────────────────────────────────────────────────────────


# ── V2 Intelligence Engine Dashboard ────────────────────────────────────────

@router.get("/intelligence-stats")
def get_intelligence_stats(
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(check_permissions("Manage Roles")),
) -> Any:
    """Get V2 Intelligence Engine statistics for SuperAdmins."""
    from app.models.ingestion import NewsSource, CrawlerLog, RawArticle
    from app.models.ai import IntentLog
    
    total_sources = db.query(NewsSource).count()
    failed_sources = db.query(NewsSource).filter(NewsSource.failure_count > 0).count()
    
    total_raw_articles = db.query(RawArticle).count()
    processed_articles = db.query(RawArticle).filter(RawArticle.status == "processed").count()
    
    total_intents = db.query(IntentLog).count()
    
    recent_crawler_logs = db.query(CrawlerLog).order_by(CrawlerLog.created_at.desc()).limit(10).all()
    
    return {
        "scraper_status": {
            "total_sources": total_sources,
            "failed_sources": failed_sources,
            "total_articles_scraped": total_raw_articles,
            "articles_processed": processed_articles,
            "recent_logs": [
                {
                    "source_id": log.source_id,
                    "status": log.status,
                    "articles_found": log.articles_found,
                    "created_at": log.created_at.isoformat() if log.created_at else None
                }
                for log in recent_crawler_logs
            ]
        },
        "ai_status": {
            "total_ai_intents_processed": total_intents,
        }
    }

# ── Bulk Actions & Help Desk ───────────────────────────────────────────────

class BulkAction(BaseModel):
    user_ids: List[int]
    action: str # suspend, restore, delete

@router.post("/users/bulk-action")
def perform_bulk_action(
    payload: BulkAction,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(check_permissions("Write", "Suspend")),
) -> Any:
    """Perform bulk actions on users."""
    users = db.query(UserModel).filter(UserModel.id.in_(payload.user_ids)).all()
    for user in users:
        # Protection against self/admin targeting
        if user.id == current_user.id or (user.role and user.role.name == "Super Admin"):
            continue
            
        if payload.action == "suspend":
            user.is_active = False
            user.is_banned = True
        elif payload.action == "restore":
            user.is_active = True
            user.is_banned = False
        elif payload.action == "delete":
            # For bulk delete, only Super Admins bypass 3-approval rule
            if current_user.role.name == "Super Admin":
                user.is_active = False
                user.email = f"archived_{user.id}_{user.email}"
                user.username = f"archived_{user.id}_{user.username}"
                
    db.commit()
    log_admin_action(db, current_user.id, f"bulk_{payload.action}", details={"user_ids": payload.user_ids})
    return {"message": f"Bulk {payload.action} executed on {len(users)} users."}

from app.models.support import SupportTicket

@router.put("/tickets/{ticket_id}/escalate")
def escalate_ticket(
    ticket_id: int,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(check_permissions("Read")), # Agents/Admins can escalate
) -> Any:
    """Escalates a Help Desk ticket from AI -> Admin -> Super Admin."""
    ticket = db.query(SupportTicket).filter(SupportTicket.id == ticket_id).first()
    if not ticket:
        raise HTTPException(status_code=404, detail="Ticket not found")
        
    if ticket.status == "ai_assigned":
        ticket.status = "open" # Escalate to Admin pool
    elif ticket.status in ("open", "pending"):
        ticket.status = "escalated_to_superadmin" # Escalate to Super Admin
        ticket.priority = "high"
        
    db.commit()
    return {"message": f"Ticket escalated. New status: {ticket.status}"}

from app.models.community import Event, ChatMessage, Question, Answer, Listing

@router.delete("/content/{content_type}/{item_id}")
def superadmin_delete_content(
    content_type: str,
    item_id: int,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(check_permissions("Delete")),
) -> Any:
    """Super Admin literally option to delete anything."""
    if current_user.role.name != "Super Admin":
        raise HTTPException(status_code=403, detail="Only Super Admins can use absolute delete")
        
    model = None
    if content_type == "news":
        model = NewsModel
    elif content_type == "event":
        model = Event
    elif content_type == "message":
        model = ChatMessage
    elif content_type == "post":
        model = Question
    elif content_type == "listing":
        model = Listing
    else:
        raise HTTPException(status_code=400, detail="Invalid content type")
        
    item = db.query(model).filter(model.id == item_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
        
    db.delete(item)
    db.commit()
    log_admin_action(db, current_user.id, f"super_delete_{content_type}", target_id=item_id)
    return {"message": f"Deleted {content_type} with ID {item_id}"}


# ── Roles Management ──────────────────────────────────────────────────────────

@router.get("/roles")
def list_all_roles(
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(check_permissions("Manage Roles")),
) -> Any:
    """List all available roles with user counts."""
    from app.models.v4_extensions import Permission
    roles = db.query(RoleModel).all()
    result = []
    for role in roles:
        user_count = db.query(UserModel).filter(UserModel.role_id == role.id).count()
        result.append({
            "id": role.id,
            "name": role.name,
            "user_count": user_count,
        })
    return result


@router.get("/permissions")
def list_all_permissions(
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(check_permissions("Manage Roles")),
) -> Any:
    """List all permissions."""
    from app.models.v4_extensions import Permission
    perms = db.query(Permission).order_by(Permission.name).all()
    return [{"id": p.id, "name": p.name, "description": p.description} for p in perms]


@router.post("/roles")
def create_role(
    role_in: RoleAssign,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(check_permissions("Manage Roles")),
) -> Any:
    """Create a new role."""
    if current_user.role and current_user.role.name != "Super Admin":
        raise HTTPException(status_code=403, detail="Only Super Admins can create roles")
    existing = db.query(RoleModel).filter(RoleModel.name == role_in.role_name).first()
    if existing:
        raise HTTPException(status_code=400, detail="Role already exists")
    role = RoleModel(name=role_in.role_name)
    db.add(role)
    db.commit()
    db.refresh(role)
    log_admin_action(db, current_user.id, "create_role", details={"role": role_in.role_name})
    return {"id": role.id, "name": role.name, "message": f"Role '{role.name}' created"}


@router.delete("/roles/{role_id}")
def delete_role(
    role_id: int,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(check_permissions("Manage Roles")),
) -> Any:
    """Delete a role (cannot delete system roles)."""
    if current_user.role and current_user.role.name != "Super Admin":
        raise HTTPException(status_code=403, detail="Only Super Admins can delete roles")
    protected = ["Super Admin", "Admin", "Moderator", "User", "Citizen"]
    role = db.query(RoleModel).filter(RoleModel.id == role_id).first()
    if not role:
        raise HTTPException(status_code=404, detail="Role not found")
    if role.name in protected:
        raise HTTPException(status_code=400, detail=f"Cannot delete system role '{role.name}'")
    db.delete(role)
    db.commit()
    log_admin_action(db, current_user.id, "delete_role", details={"role": role.name})
    return {"message": f"Role '{role.name}' deleted"}


# ── Shop Management (Admin) ───────────────────────────────────────────────────

@router.get("/shops")
def admin_list_shops(
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(check_permissions("Manage Shops")),
    status: Optional[str] = Query("pending", description="pending | approved | all"),
) -> Any:
    """[Admin] List shops by approval status."""
    from app.models.shop import Shop as ShopModel
    query = db.query(ShopModel)
    if status == "pending":
        query = query.filter(ShopModel.is_approved == False)
    elif status == "approved":
        query = query.filter(ShopModel.is_approved == True)
    shops = query.order_by(ShopModel.created_at.desc()).all()

    result = []
    for shop in shops:
        owner_profile = db.query(ProfileModel).filter(ProfileModel.user_id == shop.owner_id).first()
        owner_user = db.query(UserModel).filter(UserModel.id == shop.owner_id).first()
        owner_name = None
        owner_phone = None
        owner_email = None
        if owner_profile:
            owner_name = f"{owner_profile.first_name or ''} {owner_profile.last_name or ''}".strip() or None
            owner_phone = owner_profile.phone
        if owner_user:
            owner_email = owner_user.email

        from app.models.shop import ShopCategory
        cat = db.query(ShopCategory).filter(ShopCategory.id == shop.category_id).first() if shop.category_id else None

        result.append({
            "id": shop.id,
            "name": shop.name,
            "description": shop.description,
            "address": shop.address,
            "phone": shop.phone,
            "logo_url": shop.logo_url,
            "category": {"id": cat.id, "name": cat.name, "icon": cat.icon} if cat else None,
            "is_approved": shop.is_approved,
            "is_verified": shop.is_verified,
            "is_open": shop.is_open,
            "created_at": shop.created_at.isoformat() if shop.created_at else None,
            "owner_name": owner_name,
            "owner_phone": owner_phone,
            "owner_email": owner_email,
            "owner_id": shop.owner_id,
        })
    return result


@router.put("/shops/{shop_id}/approve")
def admin_approve_shop(
    shop_id: int,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(check_permissions("Manage Shops")),
) -> Any:
    """[Admin] Approve a pending shop."""
    from app.models.shop import Shop as ShopModel
    shop = db.query(ShopModel).filter(ShopModel.id == shop_id).first()
    if not shop:
        raise HTTPException(status_code=404, detail="Shop not found")
    shop.is_approved = True
    db.commit()
    try:
        from app.models.system import NotificationQueue
        db.add(NotificationQueue(
            user_id=shop.owner_id,
            title="🎉 Shop Approved!",
            message=f"Your shop '{shop.name}' has been approved and is now live on MyHarur!",
            status="unread", priority="High"
        ))
        db.commit()
    except Exception:
        pass
    log_admin_action(db, current_user.id, "approve_shop", target_id=shop_id, details={"shop": shop.name})
    return {"message": f"Shop '{shop.name}' approved", "shop_id": shop_id}


@router.put("/shops/{shop_id}/reject")
def admin_reject_shop(
    shop_id: int,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(check_permissions("Manage Shops")),
) -> Any:
    """[Admin] Reject and remove a shop."""
    from app.models.shop import Shop as ShopModel
    shop = db.query(ShopModel).filter(ShopModel.id == shop_id).first()
    if not shop:
        raise HTTPException(status_code=404, detail="Shop not found")
    shop_name = shop.name
    owner_id = shop.owner_id
    try:
        from app.models.system import NotificationQueue
        db.add(NotificationQueue(
            user_id=owner_id,
            title="Shop Not Approved",
            message=f"Your shop '{shop_name}' registration was not approved. Contact admin for details.",
            status="unread", priority="normal"
        ))
    except Exception:
        pass
    db.delete(shop)
    db.commit()
    log_admin_action(db, current_user.id, "reject_shop", target_id=shop_id, details={"shop": shop_name})
    return {"message": f"Shop '{shop_name}' rejected and removed"}


@router.put("/shops/{shop_id}/verify")
def admin_verify_shop(
    shop_id: int,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(check_permissions("Manage Shops")),
) -> Any:
    """[Admin] Grant verified badge to a shop."""
    from app.models.shop import Shop as ShopModel
    shop = db.query(ShopModel).filter(ShopModel.id == shop_id).first()
    if not shop:
        raise HTTPException(status_code=404, detail="Shop not found")
    shop.is_verified = True
    if not shop.is_approved:
        shop.is_approved = True
    db.commit()
    log_admin_action(db, current_user.id, "verify_shop", target_id=shop_id)
    return {"message": f"Shop '{shop.name}' is now verified"}


@router.get("/stats")
def get_admin_stats_v2(
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(check_permissions("Read")),
) -> Any:
    """Get extended platform statistics."""
    from app.models.shop import Shop as ShopModel
    total_users = db.query(UserModel).count()
    active_users = db.query(UserModel).filter(UserModel.is_active == True).count()
    banned_users = db.query(UserModel).filter(UserModel.is_banned == True).count()
    pending_news = db.query(NewsModel).filter(NewsModel.is_approved == False).count()
    approved_news = db.query(NewsModel).filter(NewsModel.is_approved == True).count()
    users_no_username = db.query(UserModel).filter(UserModel.username_required == True).count()
    pending_shops = db.query(ShopModel).filter(ShopModel.is_approved == False).count()
    approved_shops = db.query(ShopModel).filter(ShopModel.is_approved == True).count()

    return {
        "total_users": total_users,
        "active_users": active_users,
        "banned_users": banned_users,
        "users_without_username": users_no_username,
        "pending_news": pending_news,
        "approved_news": approved_news,
        "pending_shops": pending_shops,
        "approved_shops": approved_shops,
    }
