from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, Text, Float
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.session import Base

class EmergencyRequest(Base):
    __tablename__ = "emergency_requests"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    emergency_type = Column(String, nullable=False) # Police, Hospital, Fire, etc.
    description = Column(Text, nullable=True)
    location_lat = Column(Float, nullable=False)
    location_lng = Column(Float, nullable=False)
    status = Column(String, default="Pending") # Pending, Completed, Cancelled, Resolved
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    resolved_at = Column(DateTime(timezone=True), nullable=True)

class NearbyHelp(Base):
    __tablename__ = "nearby_help"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    help_category = Column(String, nullable=False) # Food, Medicine, Vehicle, etc.
    description = Column(Text, nullable=False)
    location_lat = Column(Float, nullable=False)
    location_lng = Column(Float, nullable=False)
    status = Column(String, default="Active")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
