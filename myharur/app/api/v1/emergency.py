from typing import Annotated
from uuid import UUID, uuid4
from fastapi import APIRouter, Request, HTTPException, Depends
from pydantic import BaseModel, Field, ConfigDict
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from app.db.session import get_db
from app.db.idor import get_owned_resource, set_rls_context
from app.middleware.rbac import require_permission, Permission

router = APIRouter(prefix="/api/v1/emergency", tags=["Emergency"])

class CreateEmergencyRequest(BaseModel):
    model_config = ConfigDict(strict=True, extra="forbid")
    type: Annotated[str, Field(max_length=50)]
    category: Annotated[str, Field(max_length=50)]
    description: Annotated[str | None, Field(max_length=500)] = None
    lat: Annotated[float, Field(ge=-90, le=90)]
    lng: Annotated[float, Field(ge=-180, le=180)]
    photo_url: Annotated[str | None, Field(max_length=500)] = None

@router.post(
    "/",
    dependencies=[require_permission(Permission.POST_EMERGENCY)]
)
async def create_emergency(
    body: CreateEmergencyRequest,
    request: Request,
    db: AsyncSession = Depends(get_db)
):
    mmid = request.state.mmid
    await set_rls_context(db, mmid)
    
    emergency_id = str(uuid4())
    await db.execute(
        text("""
            INSERT INTO myharur.emergencies
              (id, mmid, type, category, description, lat, lng, photo_url, status, escalation_level)
            VALUES
              (:id, :mmid, :type, :category, :description, :lat, :lng, :photo_url, 'active', 0)
        """),
        {
            "id": emergency_id,
            "mmid": mmid,
            "type": body.type,
            "category": body.category,
            "description": body.description,
            "lat": body.lat,
            "lng": body.lng,
            "photo_url": body.photo_url
        }
    )
    await db.commit()
    
    return {"emergency_id": emergency_id, "status": "active"}

@router.get("/{emergency_id}")
async def get_emergency(
    emergency_id: str,
    request: Request,
    db: AsyncSession = Depends(get_db)
):
    mmid = request.state.mmid
    await set_rls_context(db, mmid)
    
    result = await db.execute(
        text("SELECT * FROM myharur.emergencies WHERE id = :id"),
        {"id": emergency_id}
    )
    row = result.mappings().one_or_none()
    if not row:
        raise HTTPException(404, "Emergency resource not found")
    
    return dict(row)
