from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, Text, Float, JSON, Index
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.session import Base


class Listing(Base):
    """Marketplace buy/sell listing."""
    __tablename__ = "listings"
    id = Column(Integer, primary_key=True, index=True)
    seller_id = Column(Integer, ForeignKey("users.id"))
    title = Column(String, nullable=False, index=True)
    description = Column(Text, nullable=True)
    price = Column(Float, nullable=False)
    discount_price = Column(Float, nullable=True)
    category = Column(String, nullable=True)  # Electronics, Furniture, Bikes, etc.
    condition = Column(String, default="Used")  # New, Used, Like New
    image_urls = Column(JSON, default=list)  # list of image URLs
    is_sold = Column(Boolean, default=False)
    is_active = Column(Boolean, default=True)
    location = Column(String, nullable=True)
    contact_phone = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())


class JobPosting(Base):
    """Jobs vacancy posting."""
    __tablename__ = "job_postings"
    id = Column(Integer, primary_key=True, index=True)
    poster_id = Column(Integer, ForeignKey("users.id"))
    title = Column(String, nullable=False)
    company = Column(String, nullable=True)
    description = Column(Text, nullable=True)
    job_type = Column(String, default="Full-time")  # Full-time, Part-time, Contract, Freelance
    salary_range = Column(String, nullable=True)
    location = Column(String, nullable=True)
    contact_phone = Column(String, nullable=True)
    contact_email = Column(String, nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class Event(Base):
    """Public events with images."""
    __tablename__ = "events"
    id = Column(Integer, primary_key=True, index=True)
    organizer_id = Column(Integer, ForeignKey("users.id"))
    title = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    event_date = Column(DateTime(timezone=True), nullable=False)
    location_name = Column(String, nullable=True)
    location_lat = Column(Float, nullable=True)
    location_lng = Column(Float, nullable=True)
    image_url = Column(String, nullable=True)
    is_approved = Column(Boolean, default=False) # Changed to default False for approval flow
    status = Column(String, default="pending", index=True) # pending, approved, rejected
    is_featured = Column(Boolean, default=False)
    is_paid = Column(Boolean, default=False)
    ticket_price = Column(Float, nullable=True)
    payment_link = Column(String, nullable=True) # Google Forms or external payment link
    max_attendees = Column(Integer, nullable=True)
    current_attendees = Column(Integer, default=0)
    chat_room_id = Column(Integer, ForeignKey("chat_rooms.id"), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    deleted_at = Column(DateTime(timezone=True), nullable=True)
    deleted_by_admin = Column(Boolean, default=False)
    delete_reason = Column(String, nullable=True)
    
    tickets = relationship("EventTicket", back_populates="event", cascade="all, delete-orphan")
    chat_room = relationship("ChatRoom")


class EventTicket(Base):
    """RSVP / Ticket for an event."""
    __tablename__ = "event_tickets"
    id = Column(Integer, primary_key=True, index=True)
    event_id = Column(Integer, ForeignKey("events.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    qr_code_data = Column(String, nullable=False, unique=True)
    status = Column(String, default="valid") # valid, checked_in, cancelled
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    event = relationship("Event", back_populates="tickets")
    user = relationship("User")


class Poll(Base):
    """Town polls."""
    __tablename__ = "polls"
    id = Column(Integer, primary_key=True, index=True)
    creator_id = Column(Integer, ForeignKey("users.id"))
    question = Column(String, nullable=False)
    is_active = Column(Boolean, default=True)
    ends_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    deleted_at = Column(DateTime(timezone=True), nullable=True)
    deleted_by_admin = Column(Boolean, default=False)
    delete_reason = Column(String, nullable=True)

    options = relationship("PollOption", back_populates="poll", cascade="all, delete-orphan")
    votes = relationship("PollVote", back_populates="poll", cascade="all, delete-orphan")


class PollOption(Base):
    __tablename__ = "poll_options"
    id = Column(Integer, primary_key=True, index=True)
    poll_id = Column(Integer, ForeignKey("polls.id"))
    text = Column(String, nullable=False)
    vote_count = Column(Integer, default=0)

    poll = relationship("Poll", back_populates="options")


class PollVote(Base):
    __tablename__ = "poll_votes"
    id = Column(Integer, primary_key=True, index=True)
    poll_id = Column(Integer, ForeignKey("polls.id"))
    option_id = Column(Integer, ForeignKey("poll_options.id"))
    user_id = Column(Integer, ForeignKey("users.id"))
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    poll = relationship("Poll", back_populates="votes")


class Question(Base):
    """Community Q&A."""
    __tablename__ = "questions"
    id = Column(Integer, primary_key=True, index=True)
    author_id = Column(Integer, ForeignKey("users.id"))
    text = Column(Text, nullable=False)
    is_resolved = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    answers = relationship("Answer", back_populates="question", cascade="all, delete-orphan")


class Answer(Base):
    __tablename__ = "answers"
    id = Column(Integer, primary_key=True, index=True)
    question_id = Column(Integer, ForeignKey("questions.id"))
    author_id = Column(Integer, ForeignKey("users.id"))
    text = Column(Text, nullable=False)
    is_accepted = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    question = relationship("Question", back_populates="answers")


class ChatRoom(Base):
    """Public community chat rooms (e.g., General, Marketplace, Events)."""
    __tablename__ = "chat_rooms"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, nullable=False)
    description = Column(String, nullable=True)
    icon = Column(String, nullable=True)
    is_public = Column(Boolean, default=True)
    is_secure = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    messages = relationship("ChatMessage", back_populates="room", cascade="all, delete-orphan")


class ChatMessage(Base):
    """Messages in a chat room."""
    __tablename__ = "chat_messages"
    __table_args__ = (
        Index('idx_chat_room_created', 'room_id', 'created_at', postgresql_using='btree'),
    )
    id = Column(Integer, primary_key=True, index=True)
    room_id = Column(Integer, ForeignKey("chat_rooms.id"), index=True)
    sender_id = Column(Integer, ForeignKey("users.id"), index=True)
    
    content = Column(Text, nullable=True) # Text can be null if it's just media
    
    # Threading
    reply_to_id = Column(Integer, ForeignKey("chat_messages.id"), nullable=True)
    
    # Media & Files
    is_voice_note = Column(Boolean, default=False)
    audio_url = Column(String, nullable=True)
    image_urls = Column(JSON, default=list)
    video_urls = Column(JSON, default=list)
    file_urls = Column(JSON, default=list)
    
    # Metadata
    mentions = Column(JSON, default=list)   # List of @mentioned usernames
    reactions = Column(JSON, default=dict)  # Emoji reactions {"👍": ["user_id_1"], "❤️": []}
    is_pinned = Column(Boolean, default=False)
    is_deleted = Column(Boolean, default=False)
    deleted_at = Column(DateTime(timezone=True), nullable=True)
    deleted_by_admin = Column(Boolean, default=False)
    delete_reason = Column(String, nullable=True)
    
    # Delivery & Localization
    status = Column(String, default="sent") # sent, delivered, seen
    translated_text = Column(JSON, default=dict) # {"ta": "...", "en": "..."}
    
    created_at = Column(DateTime(timezone=True), server_default=func.now(), index=True)
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    room = relationship("ChatRoom", back_populates="messages")
    replies = relationship("ChatMessage", backref="parent_message", remote_side=[id])
