from typing import Optional, List, Any
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
    is_sold: bool = False
    is_active: bool = True
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
    is_active: bool = True
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
    is_paid: Optional[bool] = False
    ticket_price: Optional[float] = None
    max_attendees: Optional[int] = None

class EventCreate(EventBase):
    pass

class Event(EventBase):
    id: int
    organizer_id: int
    is_approved: bool = False
    is_featured: bool = False
    current_attendees: int = 0
    created_at: datetime
    class Config:
        from_attributes = True

class EventTicketOut(BaseModel):
    id: int
    event_id: int
    user_id: int
    qr_code_data: str
    status: str
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
    creator_id: Optional[int] = None
    question: str
    is_active: bool = True
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
    is_accepted: bool = False
    created_at: datetime
    author_name: Optional[str] = None
    author_role: Optional[str] = None
    class Config:
        from_attributes = True

class QuestionOut(BaseModel):
    id: int
    author_id: int
    text: str
    is_resolved: bool = False
    created_at: datetime
    answers: List[AnswerOut] = []
    author_name: Optional[str] = None
    author_role: Optional[str] = None
    class Config:
        from_attributes = True


# ── Chat ─────────────────────────────────────────────────────────────────────
class ChatMessageCreate(BaseModel):
    content: Optional[str] = None
    reply_to_id: Optional[int] = None
    is_voice_note: Optional[bool] = False
    audio_url: Optional[str] = None
    image_urls: Optional[List[str]] = []
    video_urls: Optional[List[str]] = []
    file_urls: Optional[List[str]] = []

class ChatMessageOut(BaseModel):
    id: int
    room_id: int
    sender_id: int
    content: Optional[str] = None
    reply_to_id: Optional[int] = None
    is_voice_note: bool = False
    audio_url: Optional[str] = None
    image_urls: List[str] = []
    video_urls: List[str] = []
    file_urls: List[str] = []
    reactions: dict = {}
    is_pinned: bool = False
    status: Optional[str] = "sent"
    translated_text: Any = {}
    created_at: datetime
    updated_at: Optional[datetime] = None
    sender_name: Optional[str] = None
    sender_role: Optional[str] = None
    sender_avatar: Optional[str] = None
    username: Optional[str] = None        # @username of sender
    display_name: Optional[str] = None   # Display name of sender
    mentions: Optional[List[str]] = []   # @mentioned usernames in message
    class Config:
        from_attributes = True

class ChatRoomOut(BaseModel):
    id: int
    name: str
    description: Optional[str]
    icon: Optional[str]
    is_secure: bool = False
    class Config:
        from_attributes = True
