from uuid import UUID
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from fastapi import HTTPException

async def get_owned_resource(
    model,
    resource_id: UUID,
    mmid: UUID,
    db: AsyncSession,
    owner_field: str = "mmid"
):
    """
    Fetch resource and verify ownership. Raises 404 if not found, 403 if
    not owned. Use on EVERY endpoint that accesses a specific user resource.
    Never returns 404 for ownership failure to prevent enumeration.
    """
    resource = await db.get(model, resource_id)
    if resource is None:
        raise HTTPException(404, "Resource not found")
    
    owner = getattr(resource, owner_field, None)
    if owner is None:
        for field in ("user_mmid", "owner_mmid", "buyer_mmid", "employer_mmid"):
            owner = getattr(resource, field, None)
            if owner is not None:
                break
    
    if str(owner) != str(mmid):
        raise HTTPException(403, "Access denied")
    
    return resource

async def set_rls_context(db: AsyncSession, mmid: str):
    """Set PostgreSQL session variable for RLS policies."""
    try:
        await db.execute(
            text("SET LOCAL app.current_mmid = :mmid"),
            {"mmid": str(mmid)}
        )
    except Exception:
        pass
