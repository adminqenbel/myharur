from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Float
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.session import Base

class UserReputation(Base):
    __tablename__ = "user_reputation"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True, nullable=False)
    
    # Core Engine Scores
    trust_score = Column(Float, default=0.0)
    community_score = Column(Float, default=0.0)
    contribution_score = Column(Float, default=0.0)
    emergency_score = Column(Float, default=0.0)
    volunteer_score = Column(Float, default=0.0)
    business_score = Column(Float, default=0.0)
    government_trust_score = Column(Float, default=0.0)
    
    # Base Stats
    upvotes = Column(Integer, default=0)
    downvotes = Column(Integer, default=0)
    helpful_answers = Column(Integer, default=0)
    events_attended = Column(Integer, default=0)
    news_reported = Column(Integer, default=0)
    emergencies_responded = Column(Integer, default=0)
    
    # Derived
    reputation_score = Column(Float, default=0.0) # Calculated moving average
    tier_badge = Column(String, default="Bronze") # Bronze, Silver, Gold, Platinum, Diamond, Ruby, Emerald, Elite, Legend
    verification_level = Column(String, default="Citizen") # Citizen, Verified Citizen, Business, Government, Police, Hospital, NGO, Reporter, Volunteer
    achievements = Column(String, default="[]") # JSON list of achievement IDs
    
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    user = relationship("User", foreign_keys=[user_id])
