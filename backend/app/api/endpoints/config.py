from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.orm import Session
from app.api import deps
from app.models.system import SystemSetting
from app.models.user import User

router = APIRouter()

class AppConfig(BaseModel):
    min_version: str
    latest_version: str
    update_url: str
    maintenance_mode: bool

@router.get("/", response_model=AppConfig)
def get_config(db: Session = Depends(deps.get_db)):
    """
    Retrieve application config (versioning, update urls, maintenance mode)
    """
    setting = db.query(SystemSetting).filter(SystemSetting.key == "maintenance_mode").first()
    is_maintenance = setting.value.lower() == "true" if setting else False

    return AppConfig(
        min_version="2026.1.0",
        latest_version="2026.1.0",
        update_url="https://myharur.onrender.com",
        maintenance_mode=is_maintenance
    )

class MaintenanceUpdate(BaseModel):
    maintenance_mode: bool

@router.post("/maintenance", response_model=AppConfig)
def toggle_maintenance(
    payload: MaintenanceUpdate,
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_user)
):
    """
    Admin only: Toggle maintenance mode
    """
    if current_user.role.name not in ["Admin", "Super Admin"]:
        raise HTTPException(status_code=403, detail="Not authorized")
        
    setting = db.query(SystemSetting).filter(SystemSetting.key == "maintenance_mode").first()
    if not setting:
        setting = SystemSetting(key="maintenance_mode", value=str(payload.maintenance_mode).lower())
        db.add(setting)
    else:
        setting.value = str(payload.maintenance_mode).lower()
    
    db.commit()
    return get_config(db)
