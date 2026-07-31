from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Float
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.session import Base

class UserReputation(Base):
    __tablename__ = "user_reputation"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True, nullable=False)
    upvotes = Column(Integer, default=0)
    downvotes = Column(Integer, default=0)
    helpful_answers = Column(Integer, default=0)
    events_attended = Column(Integer, default=0)
    reputation_score = Column(Float, default=0.0) # Calculated moving average
    tier_badge = Column(String, default="Bronze") # Bronze, Silver, Gold, Platinum
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    user = relationship("User", foreign_keys=[user_id])
