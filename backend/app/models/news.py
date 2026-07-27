from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, Text, Float
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.session import Base

class NewsCategory(Base):
    __tablename__ = "news_categories"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, index=True)

class News(Base):
    __tablename__ = "news"
    id = Column(Integer, primary_key=True, index=True)
    author_id = Column(Integer, ForeignKey("users.id"))
    category_id = Column(Integer, ForeignKey("news_categories.id"), nullable=True)
    title = Column(String, index=True, nullable=False)
    description = Column(Text, nullable=False)
    content = Column(Text, nullable=True)  # Extended content / body
    image_url = Column(String, nullable=True)  # Single hero image URL
    location_name = Column(String, nullable=True)
    location_lat = Column(Float, nullable=True)
    location_lng = Column(Float, nullable=True)
    is_approved = Column(Boolean, default=False)
    is_pinned = Column(Boolean, default=False)
    is_trending = Column(Boolean, default=False)
    is_breaking = Column(Boolean, default=False)
    verified_by = Column(Integer, ForeignKey("users.id"), nullable=True)
    verified_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    images = relationship("NewsImage", back_populates="news")
    comments = relationship("Comment", back_populates="news")
    likes = relationship("Like", back_populates="news")

class NewsImage(Base):
    __tablename__ = "news_images"
    id = Column(Integer, primary_key=True, index=True)
    news_id = Column(Integer, ForeignKey("news.id"))
    image_url = Column(String, nullable=False)

    news = relationship("News", back_populates="images")

class Comment(Base):
    __tablename__ = "comments"
    id = Column(Integer, primary_key=True, index=True)
    news_id = Column(Integer, ForeignKey("news.id"))
    user_id = Column(Integer, ForeignKey("users.id"))
    content = Column(Text, nullable=False)
    is_approved = Column(Boolean, default=True) # Moderators can remove it
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    news = relationship("News", back_populates="comments")

class Like(Base):
    __tablename__ = "likes"
    id = Column(Integer, primary_key=True, index=True)
    news_id = Column(Integer, ForeignKey("news.id"))
    user_id = Column(Integer, ForeignKey("users.id"))

    news = relationship("News", back_populates="likes")
