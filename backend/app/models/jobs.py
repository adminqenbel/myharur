from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Float, Text, Boolean
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.session import Base

class JobListing(Base):
    __tablename__ = "job_listings"
    id = Column(Integer, primary_key=True, index=True)
    employer_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    title = Column(String, nullable=False, index=True)
    company_name = Column(String, nullable=True)
    job_type = Column(String, index=True) # Full-time, Part-time, Temporary, Volunteer, Internship
    description = Column(Text, nullable=False)
    salary_range = Column(String, nullable=True)
    location = Column(String, nullable=True)
    location_lat = Column(Float, nullable=True)
    location_lng = Column(Float, nullable=True)
    contact_phone = Column(String, nullable=True)
    is_employer_verified = Column(Boolean, default=False)
    status = Column(String, default="active") # active, filled, closed
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    employer = relationship("User", foreign_keys=[employer_id])
