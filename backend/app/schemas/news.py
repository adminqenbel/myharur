from typing import Optional, List
from pydantic import BaseModel
from datetime import datetime

class NewsBase(BaseModel):
    title: str
    description: str
    category_id: Optional[int] = None
    location_name: Optional[str] = None
    location_lat: Optional[float] = None
    location_lng: Optional[float] = None
    image_url: Optional[str] = None

class NewsCreate(NewsBase):
    pass

class NewsUpdate(NewsBase):
    title: Optional[str] = None
    description: Optional[str] = None
    category_id: Optional[int] = None

class NewsApprove(BaseModel):
    """Used by admin/moderator to approve or reject news."""
    is_approved: bool

class News(NewsBase):
    id: int
    author_id: int
    is_approved: bool
    is_pinned: bool
    is_trending: bool
    is_breaking: bool
    verified_by: Optional[int] = None
    verified_at: Optional[datetime] = None
    created_at: datetime

    class Config:
        from_attributes = True

class NewsOut(BaseModel):
    """Unified output format for both DB news and RSS news."""
    id: Optional[int] = None
    title: str
    content: Optional[str] = None
    source: Optional[str] = None
    url: Optional[str] = None
    image_url: Optional[str] = None
    created_at: Optional[str] = None
    author_name: Optional[str] = None
    is_approved: bool = True
