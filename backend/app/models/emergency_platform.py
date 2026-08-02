from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Float, Text
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.session import Base
from sqlalchemy.dialects.postgresql import JSONB

class Emergency(Base):
    __tablename__ = "emergencies"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    type = Column(String, nullable=False, index=True) # citizen_sos, govt_grievance
    category = Column(String, nullable=False, index=True) # blood, medical, road, water, police, fire, transport, etc.
    description = Column(Text, nullable=True)
    status = Column(String, default="created", index=True) # SOS: accepted, on_the_way, reached, completed | Govt: created, assigned, accepted, in_progress, resolved, closed
    
    # Location
    lat = Column(Float, nullable=True)
    lng = Column(Float, nullable=True)
    
    # Media
    photo_url = Column(String, nullable=True)
    video_url = Column(String, nullable=True)
    voice_url = Column(String, nullable=True)
    
    # Escalation & Tracking
    escalation_level = Column(String, default="1km") # 1km, 5km, 10km, govt, police, hospital
    assigned_to = Column(Integer, ForeignKey("users.id"), nullable=True)
    eta_minutes = Column(Integer, nullable=True)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    resolved_at = Column(DateTime(timezone=True), nullable=True)
    
    user = relationship("User", foreign_keys=[user_id])
    responder = relationship("User", foreign_keys=[assigned_to])

    @property
    def user_name(self):
        if self.user:
            return self.user.display_name or self.user.username
        return "Citizen"

    @property
    def responder_name(self):
        if self.responder:
            return self.responder.display_name or self.responder.username
        return None
