from typing import Optional, List
from pydantic import BaseModel
from datetime import datetime

class NewsBase(BaseModel):
    title: str
    description: str
    category_id: int
    location_name: Optional[str] = None
    location_lat: Optional[float] = None
    location_lng: Optional[float] = None

class NewsCreate(NewsBase):
    pass

class NewsUpdate(NewsBase):
    title: Optional[str] = None
    description: Optional[str] = None
    category_id: Optional[int] = None

class News(NewsBase):
    id: int
    author_id: int
    is_approved: bool
    is_pinned: bool
    is_trending: bool
    is_breaking: bool
    created_at: datetime

    class Config:
        from_attributes = True
