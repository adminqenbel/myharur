from typing import Optional
from pydantic import BaseModel
from datetime import datetime

class EmergencyBase(BaseModel):
    type: str # citizen_sos, govt_grievance
    category: str # blood, medical, road, water
    lat: Optional[float] = None
    lng: Optional[float] = None

class EmergencyCreate(EmergencyBase):
    pass

class EmergencyOut(EmergencyBase):
    id: int
    user_id: int
    status: str
    radius_escalation: int
    created_at: datetime

    class Config:
        from_attributes = True

