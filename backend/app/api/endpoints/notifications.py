from typing import Any, List
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from datetime import datetime
from pydantic import BaseModel

from app.api import deps
from app.models.system import NotificationQueue
from app.models.user import User as UserModel

router = APIRouter()

class NotificationOut(BaseModel):
    id: int
    title: str
    message: str
    status: str
    priority: str
    created_at: datetime
    is_read: bool = False

@router.get("/", response_model=List[NotificationOut])
def get_notifications(
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    """Get all notifications for the current user and broadcasts."""
    notifications = (
        db.query(NotificationQueue)
        .filter(
            (NotificationQueue.user_id == current_user.id) | (NotificationQueue.user_id == None)
        )
        .order_by(NotificationQueue.created_at.desc())
        .limit(50)
        .all()
    )
    
    result = []
    for n in notifications:
        result.append(NotificationOut(
            id=n.id,
            title=n.title,
            message=n.message,
            status=n.status,
            priority=n.priority,
            created_at=n.created_at,
            is_read=True if n.status == "read" else False # We'll repurpose status to track read state for simplicity
        ))
    return result

@router.put("/{notif_id}/read")
def mark_notification_read(
    notif_id: int,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    n = db.query(NotificationQueue).filter(NotificationQueue.id == notif_id).first()
    if n and (n.user_id == current_user.id or n.user_id is None):
        n.status = "read"
        db.commit()
    return {"message": "Marked as read"}
