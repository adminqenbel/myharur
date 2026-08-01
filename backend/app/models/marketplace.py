from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Float, Text
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.session import Base

class MarketplaceListing(Base):
    __tablename__ = "marketplace_listings"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    type = Column(String, nullable=False, index=True) # sell, rental, exchange, wanted
    category = Column(String, index=True, nullable=True)
    title = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    condition = Column(String, nullable=True) # Used, Like New, New
    price = Column(Float, nullable=True)
    image_url = Column(String, nullable=True)
    video_url = Column(String, nullable=True)
    contact_phone = Column(String, nullable=True)
    location_lat = Column(Float, nullable=True)
    location_lng = Column(Float, nullable=True)
    status = Column(String, default="active", index=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), index=True)
    
    user = relationship("User", foreign_keys=[user_id])
