from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, JSON
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.session import Base

class AuditLog(Base):
    __tablename__ = "audit_logs"
    id = Column(Integer, primary_key=True, index=True)
    admin_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    action = Column(String, nullable=False)  # e.g., 'suspend_user', 'delete_user'
    target_id = Column(Integer, nullable=True) # e.g., user_id affected
    details = Column(JSON, nullable=True) # additional metadata
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    admin = relationship("User", foreign_keys=[admin_id])

class DeletionRequest(Base):
    __tablename__ = "deletion_requests"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    approvals = Column(JSON, nullable=True) # list of admin IDs who approved
    status = Column(String, default="pending") # pending, approved, rejected, executed
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    user = relationship("User", foreign_keys=[user_id])
