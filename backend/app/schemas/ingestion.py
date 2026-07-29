from typing import Optional, List, Any
from pydantic import BaseModel
from datetime import datetime

class NewsSourceBase(BaseModel):
    name: str
    url: str
    source_type: str
    reliability_score: Optional[float] = 1.0
    priority: Optional[int] = 1
    is_active: Optional[bool] = True
    refresh_interval_minutes: Optional[int] = 120

class NewsSourceCreate(NewsSourceBase):
    pass

class NewsSourceUpdate(BaseModel):
    name: Optional[str] = None
    url: Optional[str] = None
    source_type: Optional[str] = None
    reliability_score: Optional[float] = None
    priority: Optional[int] = None
    is_active: Optional[bool] = None
    refresh_interval_minutes: Optional[int] = None

class NewsSource(NewsSourceBase):
    id: int
    failure_count: int
    last_successful_sync: Optional[datetime] = None
    created_at: datetime

    class Config:
        orm_mode = True

class CrawlerLogBase(BaseModel):
    source_id: int
    status: str
    articles_found: int = 0
    error_message: Optional[str] = None

class CrawlerLogCreate(CrawlerLogBase):
    pass

class CrawlerLog(CrawlerLogBase):
    id: int
    created_at: datetime

    class Config:
        orm_mode = True

class RawArticleBase(BaseModel):
    source_id: int
    original_url: str
    raw_html: Optional[str] = None
    raw_json: Optional[Any] = None
    extracted_title: Optional[str] = None
    extracted_text: Optional[str] = None
    status: str = "pending"

class RawArticleCreate(RawArticleBase):
    pass

class RawArticle(RawArticleBase):
    id: int
    created_at: datetime

    class Config:
        orm_mode = True
