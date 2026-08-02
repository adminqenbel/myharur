from typing import Optional
from pydantic import BaseModel
from datetime import datetime

class EmergencyBase(BaseModel):
    type: str # citizen_sos, govt_grievance
    category: str # blood, medical, police, fire, road, water, electricity
    description: Optional[str] = None
    lat: Optional[float] = None
    lng: Optional[float] = None
    photo_url: Optional[str] = None
    video_url: Optional[str] = None
    voice_url: Optional[str] = None

class EmergencyCreate(EmergencyBase):
    pass

class EmergencyOut(EmergencyBase):
    id: int
    user_id: int
    user_name: Optional[str] = None
    status: str
    escalation_level: str
    eta_minutes: Optional[int] = None
    assigned_to: Optional[int] = None
    responder_name: Optional[str] = None
    created_at: datetime
    updated_at: Optional[datetime] = None
    resolved_at: Optional[datetime] = None

    class Config:
        from_attributes = True

