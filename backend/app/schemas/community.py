from typing import Optional, List
from pydantic import BaseModel
from datetime import datetime


# ── Marketplace ──────────────────────────────────────────────────────────────
class ListingBase(BaseModel):
    title: str
    description: Optional[str] = None
    price: float
    discount_price: Optional[float] = None
    category: Optional[str] = None
    condition: str = "Used"
    image_urls: Optional[List[str]] = []
    location: Optional[str] = None
    contact_phone: Optional[str] = None

class ListingCreate(ListingBase):
    pass

class ListingUpdate(BaseModel):
    is_sold: Optional[bool] = None
    is_active: Optional[bool] = None
    price: Optional[float] = None
    discount_price: Optional[float] = None

class Listing(ListingBase):
    id: int
    seller_id: int
    is_sold: bool
    is_active: bool
    created_at: datetime
    class Config:
        from_attributes = True


# ── Jobs ─────────────────────────────────────────────────────────────────────
class JobPostingBase(BaseModel):
    title: str
    company: Optional[str] = None
    description: Optional[str] = None
    job_type: str = "Full-time"
    salary_range: Optional[str] = None
    location: Optional[str] = None
    contact_phone: Optional[str] = None
    contact_email: Optional[str] = None

class JobPostingCreate(JobPostingBase):
    pass

class JobPosting(JobPostingBase):
    id: int
    poster_id: int
    is_active: bool
    created_at: datetime
    class Config:
        from_attributes = True


# ── Events ───────────────────────────────────────────────────────────────────
class EventBase(BaseModel):
    title: str
    description: Optional[str] = None
    event_date: datetime
    location_name: Optional[str] = None
    image_url: Optional[str] = None

class EventCreate(EventBase):
    pass

class Event(EventBase):
    id: int
    organizer_id: int
    is_approved: bool
    created_at: datetime
    class Config:
        from_attributes = True


# ── Polls ────────────────────────────────────────────────────────────────────
class PollOptionBase(BaseModel):
    text: str

class PollCreate(BaseModel):
    question: str
    options: List[str]
    ends_at: Optional[datetime] = None

class PollOptionOut(BaseModel):
    id: int
    text: str
    vote_count: int
    class Config:
        from_attributes = True

class PollOut(BaseModel):
    id: int
    question: str
    is_active: bool
    created_at: datetime
    options: List[PollOptionOut] = []
    user_voted_option_id: Optional[int] = None
    class Config:
        from_attributes = True

class VoteIn(BaseModel):
    option_id: int


# ── Q&A ──────────────────────────────────────────────────────────────────────
class QuestionCreate(BaseModel):
    text: str

class AnswerCreate(BaseModel):
    text: str

class AnswerOut(BaseModel):
    id: int
    author_id: int
    text: str
    is_accepted: bool
    created_at: datetime
    author_name: Optional[str] = None
    author_role: Optional[str] = None
    class Config:
        from_attributes = True

class QuestionOut(BaseModel):
    id: int
    author_id: int
    text: str
    is_resolved: bool
    created_at: datetime
    answers: List[AnswerOut] = []
    author_name: Optional[str] = None
    author_role: Optional[str] = None
    class Config:
        from_attributes = True


# ── Chat ─────────────────────────────────────────────────────────────────────
class ChatMessageCreate(BaseModel):
    content: str

class ChatMessageOut(BaseModel):
    id: int
    room_id: int
    sender_id: int
    content: str
    created_at: datetime
    sender_name: Optional[str] = None
    sender_role: Optional[str] = None
    sender_avatar: Optional[str] = None
    class Config:
        from_attributes = True

class ChatRoomOut(BaseModel):
    id: int
    name: str
    description: Optional[str]
    icon: Optional[str]
    class Config:
        from_attributes = True
