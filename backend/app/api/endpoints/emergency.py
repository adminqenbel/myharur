from typing import Any, List
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api import deps
from app.schemas.emergency import EmergencyRequest, EmergencyRequestCreate
from app.models.emergency import EmergencyRequest as EmergencyModel
from app.models.user import User as UserModel

router = APIRouter()

@router.get("/", response_model=List[EmergencyRequest])
def read_emergencies(
    db: Session = Depends(deps.get_db),
    skip: int = 0,
    limit: int = 100,
) -> Any:
    """
    Retrieve active emergencies.
    """
    emergencies = db.query(EmergencyModel).filter(EmergencyModel.status != "Resolved").order_by(EmergencyModel.created_at.desc()).offset(skip).limit(limit).all()
    return emergencies

@router.post("/", response_model=EmergencyRequest)
def create_emergency(
    *,
    db: Session = Depends(deps.get_db),
    emergency_in: EmergencyRequestCreate,
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    """
    Create new emergency SOS.
    """
    emergency = EmergencyModel(
        user_id=current_user.id,
        **emergency_in.dict()
    )
    db.add(emergency)
    db.commit()
    db.refresh(emergency)
    return emergency
