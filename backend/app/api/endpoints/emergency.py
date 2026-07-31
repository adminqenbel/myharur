from typing import Any, List
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

    if emergency.radius_escalation < 10:
        if emergency.radius_escalation == 1:
            emergency.radius_escalation = 5
        elif emergency.radius_escalation == 5:
            emergency.radius_escalation = 10
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
