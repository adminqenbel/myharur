from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Float
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.session import Base

class Emergency(Base):
    __tablename__ = "emergencies"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    type = Column(String, nullable=False, index=True) # citizen_sos, govt_grievance
    category = Column(String, nullable=False, index=True) # blood, medical, road, water
    status = Column(String, default="created", index=True) # created, assigned, in_progress, resolved
    lat = Column(Float, nullable=True)
    lng = Column(Float, nullable=True)
    radius_escalation = Column(Integer, default=1)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    user = relationship("User", foreign_keys=[user_id])
