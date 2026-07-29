from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, Text, JSON, Float
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.session import Base

class KnowledgeBase(Base):
    __tablename__ = "knowledge_base"
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, index=True, nullable=False)
    content = Column(Text, nullable=False)
    tags = Column(String, nullable=True) # comma separated
    embedding = Column(JSON, nullable=True) # for vector search if using PGVector, otherwise JSON for generic storage
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

class FAQ(Base):
    __tablename__ = "faqs"
    id = Column(Integer, primary_key=True, index=True)
    question = Column(String, index=True, nullable=False)
    answer = Column(Text, nullable=False)
    category = Column(String, index=True, nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class ChatSession(Base):
    __tablename__ = "chat_sessions"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True) # nullable for guests
    session_token = Column(String, unique=True, index=True, nullable=False)
    context_data = Column(JSON, nullable=True) # Stores recent conversation context/variables
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    command_history = relationship("CommandHistory", back_populates="session")

class CommandHistory(Base):
    __tablename__ = "command_history"
    id = Column(Integer, primary_key=True, index=True)
    session_id = Column(Integer, ForeignKey("chat_sessions.id"), nullable=False)
    command_text = Column(String, nullable=False)
    ai_response = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    session = relationship("ChatSession", back_populates="command_history")

class IntentLog(Base):
    __tablename__ = "intent_logs"
    id = Column(Integer, primary_key=True, index=True)
    user_input = Column(String, nullable=False)
    detected_intent = Column(String, nullable=True)
    confidence_score = Column(Float, nullable=True)
    is_escalated = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
