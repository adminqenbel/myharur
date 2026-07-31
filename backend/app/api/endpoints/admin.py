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
    q: Optional[str] = Query(None, description="Search by username, MID, email, display name"),
    current_user: UserModel = Depends(_require_admin),
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
    users = query.offset(skip).limit(limit).all()
    return users


@router.get("/users/export")
def export_users_csv(
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(_require_admin),
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
    log_admin_action(db, current_user.id, "assign_role", target_id=user_id, details={"role": role_in.role_name})
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
    log_admin_action(db, current_user.id, "toggle_active", target_id=user_id, details={"is_active": user.is_active})
    return {"message": "User status updated", "is_active": user.is_active}


@router.put("/users/{user_id}/ban")
def ban_user(
    user_id: int,
    ban_in: BanUser,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(_require_admin),
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
    current_user: UserModel = Depends(_require_admin),
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
    current_user: UserModel = Depends(_require_admin),
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
    current_user: UserModel = Depends(_require_admin),
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
    current_user: UserModel = Depends(_require_admin),
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


# ── Stats ─────────────────────────────────────────────────────────────────

@router.get("/stats")
def get_admin_stats(
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(_require_moderator),
) -> Any:
    """Get platform statistics."""
    total_users = db.query(UserModel).count()
    active_users = db.query(UserModel).filter(UserModel.is_active == True).count()
    banned_users = db.query(UserModel).filter(UserModel.is_banned == True).count()
    pending_news = db.query(NewsModel).filter(NewsModel.is_approved == False).count()
    approved_news = db.query(NewsModel).filter(NewsModel.is_approved == True).count()
    users_no_username = db.query(UserModel).filter(UserModel.username_required == True).count()

    return {
        "total_users": total_users,
        "active_users": active_users,
        "banned_users": banned_users,
        "users_without_username": users_no_username,
        "pending_news": pending_news,
        "approved_news": approved_news,
    }

# ── V2 Intelligence Engine Dashboard ────────────────────────────────────────

@router.get("/intelligence-stats")
def get_intelligence_stats(
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(_require_superadmin),
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
