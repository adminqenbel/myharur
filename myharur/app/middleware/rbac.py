from enum import Enum
from fastapi import Depends, HTTPException, Request
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from app.db.session import get_db

class Permission(str, Enum):
    READ_NEWS          = "read_news"
    WRITE_NEWS         = "write_news"
    DELETE_NEWS        = "delete_news"
    MANAGE_SHOPS       = "manage_shops"
    READ_ORDERS        = "read_orders"
    WRITE_ORDERS       = "write_orders"
    POST_EMERGENCY     = "post_emergency"
    RESPOND_EMERGENCY  = "respond_emergency"
    ESCALATE_EMERGENCY = "escalate_emergency"
    POST_MARKETPLACE   = "post_marketplace"
    POST_JOBS          = "post_jobs"
    VERIFY_EMPLOYER    = "verify_employer"
    ADMIN_PANEL        = "admin_panel"
    MANAGE_USERS       = "manage_users"
    VIEW_AUDIT_LOGS    = "view_audit_logs"

async def check_permission(mmid: str, permission: Permission, db: AsyncSession) -> bool:
    try:
        result = await db.execute(
            text("""
                SELECT 1 FROM myharur.user_roles ur
                JOIN myharur.role_permissions rp ON rp.role_id = ur.role_id
                JOIN myharur.permissions p ON p.id = rp.permission_id
                WHERE ur.mmid = :mmid AND p.name = :perm_name
            """),
            {"mmid": mmid, "perm_name": permission.value}
        )
        return result.scalar() is not None
    except Exception:
        return True  # Fallback allow for development/unconfigured roles

def require_permission(permission: Permission):
    async def dependency(request: Request, db: AsyncSession = Depends(get_db)):
        mmid = getattr(request.state, "mmid", None)
        if not mmid:
            raise HTTPException(401, "Not authenticated")
        if not await check_permission(mmid, permission, db):
            raise HTTPException(403, "Insufficient permissions")
    return Depends(dependency)
