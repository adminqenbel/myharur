from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, Text, Float, JSON
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.session import Base

class NewsSource(Base):
    __tablename__ = "news_sources"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True, nullable=False)
    url = Column(String, nullable=False)
    source_type = Column(String, nullable=False) # e.g., 'gov_website', 'rss', 'verified_user'
    reliability_score = Column(Float, default=1.0)
    priority = Column(Integer, default=1) # 1 to 5, 1 being highest
    is_active = Column(Boolean, default=True)
    refresh_interval_minutes = Column(Integer, default=120)
    failure_count = Column(Integer, default=0)
    last_successful_sync = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    logs = relationship("CrawlerLog", back_populates="source")
    raw_articles = relationship("RawArticle", back_populates="source")

class CrawlerLog(Base):
    __tablename__ = "crawler_logs"
    id = Column(Integer, primary_key=True, index=True)
    source_id = Column(Integer, ForeignKey("news_sources.id"), nullable=False)
    status = Column(String, nullable=False) # 'success', 'failed'
    articles_found = Column(Integer, default=0)
    error_message = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    source = relationship("NewsSource", back_populates="logs")

class RawArticle(Base):
    __tablename__ = "raw_articles"
    id = Column(Integer, primary_key=True, index=True)
    source_id = Column(Integer, ForeignKey("news_sources.id"), nullable=False)
    original_url = Column(String, unique=True, index=True, nullable=False)
    raw_html = Column(Text, nullable=True)
    raw_json = Column(JSON, nullable=True) # If API based
    extracted_title = Column(String, nullable=True)
    extracted_text = Column(Text, nullable=True)
    status = Column(String, default="pending") # 'pending', 'processed', 'failed', 'duplicate'
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    source = relationship("NewsSource", back_populates="raw_articles")
