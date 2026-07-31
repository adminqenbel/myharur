from typing import Any, List, Optional
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.api import deps
from app.schemas.emergency import EmergencyCreate, EmergencyOut
from app.models.emergency_platform import Emergency as EmergencyModel
from app.models.user import User as UserModel

router = APIRouter()

@router.get("/", response_model=List[EmergencyOut])
def read_emergencies(
    db: Session = Depends(deps.get_db),
    skip: int = 0,
    limit: int = 100,
) -> Any:
    """
    Retrieve active emergencies (not resolved).
    """
    emergencies = db.query(EmergencyModel).filter(EmergencyModel.status != "resolved").order_by(EmergencyModel.created_at.desc()).offset(skip).limit(limit).all()
    return emergencies

@router.post("/", response_model=EmergencyOut)
def create_emergency(
    *,
    db: Session = Depends(deps.get_db),
    emergency_in: EmergencyCreate,
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    """
    Create new emergency SOS or grievance.
    """
    if emergency_in.type not in ["citizen_sos", "govt_grievance"]:
        raise HTTPException(status_code=400, detail="Invalid emergency type")

    emergency = EmergencyModel(
        user_id=current_user.id,
        **emergency_in.model_dump()
    )
    db.add(emergency)
    db.commit()
    db.refresh(emergency)
    return emergency

@router.put("/{emergency_id}/escalate", response_model=EmergencyOut)
def escalate_emergency(
    emergency_id: int,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    """
    Escalate the emergency radius (1km -> 5km -> 10km).
    """
    emergency = db.query(EmergencyModel).filter(EmergencyModel.id == emergency_id).first()
    if not emergency:
        raise HTTPException(status_code=404, detail="Emergency not found")
    
    if emergency.user_id != current_user.id and current_user.role.name not in ["Admin", "Super Admin", "Emergency Admin"]:
        raise HTTPException(status_code=403, detail="Not authorized to escalate this emergency")

    levels = ["1km", "5km", "10km", "govt", "police", "hospital"]
    try:
        idx = levels.index(emergency.escalation_level)
        if idx < len(levels) - 1:
            emergency.escalation_level = levels[idx + 1]
            db.commit()
            db.refresh(emergency)
    except ValueError:
        pass
        
    return emergency

@router.put("/{emergency_id}/status", response_model=EmergencyOut)
def update_status(
    emergency_id: int,
    status: str,
    eta_minutes: Optional[int] = None,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    """
    Update status of emergency/grievance (accepted, in_progress, resolved).
    """
    emergency = db.query(EmergencyModel).filter(EmergencyModel.id == emergency_id).first()
    if not emergency:
        raise HTTPException(status_code=404, detail="Emergency not found")
        
    emergency.status = status
    if eta_minutes is not None:
        emergency.eta_minutes = eta_minutes
    if status == "accepted":
        emergency.assigned_to = current_user.id
    if status in ["resolved", "completed", "closed"]:
        from datetime import datetime
        emergency.resolved_at = datetime.utcnow()
        
    db.commit()
    db.refresh(emergency)
    return emergency

@router.put("/{emergency_id}/resolve", response_model=EmergencyOut)
def resolve_emergency(
    emergency_id: int,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    emergency = db.query(EmergencyModel).filter(EmergencyModel.id == emergency_id).first()
    if not emergency:
        raise HTTPException(status_code=404, detail="Emergency not found")
        
    if emergency.user_id != current_user.id and current_user.role.name not in ["Admin", "Super Admin", "Emergency Admin"]:
        raise HTTPException(status_code=403, detail="Not authorized")
        
    emergency.status = "resolved"
    db.commit()
    db.refresh(emergency)
    return emergency
