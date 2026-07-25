from typing import Optional
from pydantic import BaseModel
from datetime import datetime

class EmergencyRequestBase(BaseModel):
    emergency_type: str
    description: Optional[str] = None
    location_lat: float
    location_lng: float

class EmergencyRequestCreate(EmergencyRequestBase):
    pass

class EmergencyRequest(EmergencyRequestBase):
    id: int
    user_id: int
    status: str
    created_at: datetime
    resolved_at: Optional[datetime] = None

    class Config:
        orm_mode = True
