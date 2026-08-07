from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.orm import Session
from app.api import deps
from app.models.system import SystemSetting
from app.models.user import User

router = APIRouter()

class AppConfig(BaseModel):
    min_version: str = "1.0.0"
    latest_version: str = "1.2.0"
    build_number: int = 12
    update_url: str = "https://myharur.onrender.com/static/myharur.apk"
    apk_url: str = "https://myharur.onrender.com/static/myharur.apk"
    release_notes: str = "Emergency Google Maps deep-links, dynamic news ingestion, and community chat stability fixes."
    force_update: bool = False
    maintenance_mode: bool = False

def _get_setting(db: Session, key: str, default: str) -> str:
    setting = db.query(SystemSetting).filter(SystemSetting.key == key).first()
    return setting.value if setting else default

def _set_setting(db: Session, key: str, value: str):
    setting = db.query(SystemSetting).filter(SystemSetting.key == key).first()
    if not setting:
        setting = SystemSetting(key=key, value=value)
        db.add(setting)
    else:
        setting.value = value

@router.get("/", response_model=AppConfig)
def get_config(db: Session = Depends(deps.get_db)):
    """
    Retrieve application config (versioning, update urls, maintenance mode, release notes)
    """
    is_maint = _get_setting(db, "maintenance_mode", "false").lower() == "true"
    force_up = _get_setting(db, "force_update", "false").lower() == "true"
    try:
        build_num = int(_get_setting(db, "build_number", "12"))
    except ValueError:
        build_num = 12

    return AppConfig(
        min_version=_get_setting(db, "min_version", "1.0.0"),
        latest_version=_get_setting(db, "latest_version", "1.2.0"),
        build_number=build_num,
        update_url=_get_setting(db, "update_url", "https://myharur.onrender.com/static/myharur.apk"),
        apk_url=_get_setting(db, "apk_url", "https://myharur.onrender.com/static/myharur.apk"),
        release_notes=_get_setting(db, "release_notes", "Emergency Google Maps deep-links, dynamic news ingestion, and community chat stability fixes."),
        force_update=force_up,
        maintenance_mode=is_maint
    )

class VersionUpdate(BaseModel):
    latest_version: Optional[str] = None
    min_version: Optional[str] = None
    build_number: Optional[int] = None
    apk_url: Optional[str] = None
    release_notes: Optional[str] = None
    force_update: Optional[bool] = None

@router.post("/version", response_model=AppConfig)
def update_version_config(
    payload: VersionUpdate,
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_user)
):
    """
    Admin only: Update application version details & release notes
    """
    if current_user.role.name not in ["Admin", "Super Admin"]:
        raise HTTPException(status_code=403, detail="Not authorized")
        
    if payload.latest_version:
        _set_setting(db, "latest_version", payload.latest_version)
    if payload.min_version:
        _set_setting(db, "min_version", payload.min_version)
    if payload.build_number is not None:
        _set_setting(db, "build_number", str(payload.build_number))
    if payload.apk_url:
        _set_setting(db, "apk_url", payload.apk_url)
        _set_setting(db, "update_url", payload.apk_url)
    if payload.release_notes:
        _set_setting(db, "release_notes", payload.release_notes)
    if payload.force_update is not None:
        _set_setting(db, "force_update", str(payload.force_update).lower())
        
    db.commit()
    return get_config(db)

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
        
    _set_setting(db, "maintenance_mode", str(payload.maintenance_mode).lower())
    db.commit()
    return get_config(db)
