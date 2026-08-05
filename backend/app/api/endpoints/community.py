from typing import Any, List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.api import deps
from app.models.community import (
    Listing as ListingModel, JobPosting as JobModel,
    Event as EventModel, EventTicket, Poll as PollModel, PollOption, PollVote,
    Question as QuestionModel, Answer as AnswerModel,
    ChatRoom, ChatMessage
)
from app.models.user import User as UserModel, Profile as ProfileModel
from app.schemas.community import (
    ListingCreate, ListingUpdate, Listing as ListingSchema,
    JobPostingCreate, JobPosting as JobSchema,
    EventCreate, Event as EventSchema, EventTicketOut,
    PollCreate, PollOut, VoteIn,
    QuestionCreate, AnswerCreate, QuestionOut, AnswerOut,
    ChatMessageCreate, ChatMessageOut, ChatRoomOut,
)

router = APIRouter()


# ── Marketplace ───────────────────────────────────────────────────────────────

@router.get("/listings", response_model=List[ListingSchema])
def get_listings(
    db: Session = Depends(deps.get_db),
    category: Optional[str] = None,
    skip: int = 0, limit: int = 50,
) -> Any:
    q = db.query(ListingModel).filter(ListingModel.is_active == True, ListingModel.is_sold == False)
    if category:
        q = q.filter(ListingModel.category == category)
    return q.order_by(ListingModel.created_at.desc()).offset(skip).limit(limit).all()


@router.post("/listings", response_model=ListingSchema)
def create_listing(
    listing_in: ListingCreate,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    listing = ListingModel(**listing_in.dict(), seller_id=current_user.id)
    db.add(listing)
    db.commit()
    db.refresh(listing)
    return listing


@router.put("/listings/{listing_id}/sold")
def mark_sold(
    listing_id: int,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    listing = db.query(ListingModel).filter(ListingModel.id == listing_id).first()
    if not listing or listing.seller_id != current_user.id:
        raise HTTPException(status_code=404, detail="Listing not found or not yours")
    listing.is_sold = True
    db.commit()
    return {"message": "Marked as sold"}


# ── Jobs ──────────────────────────────────────────────────────────────────────

@router.get("/jobs", response_model=List[JobSchema])
def get_jobs(db: Session = Depends(deps.get_db), skip: int = 0, limit: int = 50) -> Any:
    return db.query(JobModel).filter(JobModel.is_active == True).order_by(JobModel.created_at.desc()).offset(skip).limit(limit).all()


@router.post("/jobs", response_model=JobSchema)
def create_job(
    job_in: JobPostingCreate,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    job = JobModel(**job_in.dict(), poster_id=current_user.id)
    db.add(job)
    db.commit()
    db.refresh(job)
    return job


# ── Events ────────────────────────────────────────────────────────────────────

@router.get("/events", response_model=List[EventSchema])
def get_events(db: Session = Depends(deps.get_db), skip: int = 0, limit: int = 50) -> Any:
    import datetime
    seven_days_ago = datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(days=7)
    return db.query(EventModel).filter(
        EventModel.is_approved == True,
        EventModel.event_date >= seven_days_ago
    ).order_by(EventModel.event_date).offset(skip).limit(limit).all()


@router.post("/events", response_model=EventSchema)
def create_event(
    event_in: EventCreate,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    event = EventModel(**event_in.model_dump(), organizer_id=current_user.id, status="pending")
    db.add(event)
    db.commit()
    db.refresh(event)
    return event

@router.put("/events/{event_id}/approve")
def approve_event(
    event_id: int,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    if current_user.role.name not in ["Admin", "Super Admin"]:
        raise HTTPException(status_code=403, detail="Not authorized")
        
    event = db.query(EventModel).filter(EventModel.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
        
    event.is_approved = True
    event.status = "approved"
    
    # Create Event Chat Room
    room = ChatRoom(name=f"Event: {event.title[:20]}", description=f"Chat for event {event.title}", icon="event", is_public=True)
    db.add(room)
    db.flush()
    event.chat_room_id = room.id
    
    # Assign Event Head role if they don't have a higher role
    organizer = db.query(UserModel).filter(UserModel.id == event.organizer_id).first()
    if organizer and organizer.role.name == "User":
        from app.models.user import Role
        head_role = db.query(Role).filter(Role.name == "Event Head").first()
        if head_role:
            organizer.role_id = head_role.id
            
    db.commit()
    return {"message": "Event approved, chat room created, organizer promoted to Event Head"}

@router.post("/events/{event_id}/rsvp", response_model=EventTicketOut)
def rsvp_event(
    event_id: int,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    event = db.query(EventModel).filter(EventModel.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
        
    if event.max_attendees and event.current_attendees >= event.max_attendees:
        raise HTTPException(status_code=400, detail="Event is at full capacity")
        
    existing = db.query(EventTicket).filter(EventTicket.event_id == event_id, EventTicket.user_id == current_user.id).first()
    if existing:
        return existing
        
    import uuid
    qr_data = f"event_{event_id}_user_{current_user.id}_{uuid.uuid4().hex[:8]}"
    
    ticket = EventTicket(event_id=event_id, user_id=current_user.id, qr_code_data=qr_data)
    event.current_attendees += 1
    
    db.add(ticket)
    db.commit()
    db.refresh(ticket)
    return ticket
    return ticket


@router.delete("/events/{event_id}")
def delete_event(
    event_id: int,
    reason: Optional[str] = Query(None),
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    event = db.query(EventModel).filter(EventModel.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
        
    is_admin = current_user.role.name in ["Admin", "Super Admin"]
    if event.organizer_id != current_user.id and not is_admin:
        raise HTTPException(status_code=403, detail="Not authorized to delete this event")
    
    from sqlalchemy.sql import func
    event.deleted_at = func.now()
    if is_admin and event.organizer_id != current_user.id:
        event.deleted_by_admin = True
        event.delete_reason = reason or "Violation of community guidelines"
        
    db.commit()
    return {"message": "Event deleted successfully"}

# ── Polls ─────────────────────────────────────────────────────────────────────

def _enrich_poll(poll: PollModel, user_id: Optional[int], db: Session) -> dict:
    voted = None
    if user_id:
        vote = db.query(PollVote).filter(PollVote.poll_id == poll.id, PollVote.user_id == user_id).first()
        if vote:
            voted = vote.option_id
    return {
        "id": poll.id,
        "creator_id": poll.creator_id,
        "question": poll.question,
        "is_active": poll.is_active,
        "is_active": poll.is_active,
        "created_at": poll.created_at,
        "deleted_at": poll.deleted_at,
        "deleted_by_admin": poll.deleted_by_admin,
        "delete_reason": poll.delete_reason,
        "options": poll.options,
        "user_voted_option_id": voted,
    }


@router.get("/polls", response_model=List[PollOut])
def get_polls(
    db: Session = Depends(deps.get_db),
    current_user: Optional[UserModel] = Depends(deps.get_optional_current_user),
) -> Any:
    import datetime
    seven_days_ago = datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(days=7)
    polls = db.query(PollModel).filter(
        PollModel.is_active == True,
        (PollModel.ends_at == None) | (PollModel.ends_at >= seven_days_ago)
    ).order_by(PollModel.created_at.desc()).all()
    uid = current_user.id if current_user else None
    return [_enrich_poll(p, uid, db) for p in polls]


@router.post("/polls", response_model=PollOut)
def create_poll(
    poll_in: PollCreate,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    poll = PollModel(creator_id=current_user.id, question=poll_in.question, ends_at=poll_in.ends_at)
    db.add(poll)
    db.flush()
    for opt_text in poll_in.options:
        db.add(PollOption(poll_id=poll.id, text=opt_text))
    db.commit()
    db.refresh(poll)
    return _enrich_poll(poll, current_user.id, db)


@router.post("/polls/{poll_id}/vote")
def cast_vote(
    poll_id: int,
    vote_in: VoteIn,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    existing = db.query(PollVote).filter(PollVote.poll_id == poll_id, PollVote.user_id == current_user.id).first()
    if existing:
        raise HTTPException(status_code=400, detail="Already voted")
    option = db.query(PollOption).filter(PollOption.id == vote_in.option_id, PollOption.poll_id == poll_id).first()
    if not option:
        raise HTTPException(status_code=404, detail="Option not found")
    option.vote_count = (option.vote_count or 0) + 1
    vote = PollVote(poll_id=poll_id, option_id=vote_in.option_id, user_id=current_user.id)
    db.add(vote)
    db.commit()
    return {"message": "Vote cast"}


@router.delete("/polls/{poll_id}")
def delete_poll(
    poll_id: int,
    reason: Optional[str] = Query(None),
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    poll = db.query(PollModel).filter(PollModel.id == poll_id).first()
    if not poll:
        raise HTTPException(status_code=404, detail="Poll not found")
        
    is_admin = current_user.role.name in ["Admin", "Super Admin"]
    if poll.creator_id != current_user.id and not is_admin:
        raise HTTPException(status_code=403, detail="Not authorized to delete this poll")
    
    from sqlalchemy.sql import func
    poll.deleted_at = func.now()
    if is_admin and poll.creator_id != current_user.id:
        poll.deleted_by_admin = True
        poll.delete_reason = reason or "Violation of community guidelines"
        
    db.commit()
    return {"message": "Poll deleted"}



# ── Q&A ───────────────────────────────────────────────────────────────────────

def _get_name(db: Session, user_id: int) -> str:
    user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if user:
        if user.display_name:
            return user.display_name
        if user.username:
            return f"@{user.username}"
    profile = db.query(ProfileModel).filter(ProfileModel.user_id == user_id).first()
    if profile:
        name = f"{profile.first_name or ''} {profile.last_name or ''}".strip()
        return name or "Anonymous"
    return "Anonymous"

def _get_role(db: Session, user_id: int) -> str:
    user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if user and user.role:
        return user.role.name
    return "User"

def _get_user_info(db: Session, user_id: int) -> dict:
    """Get username and display_name for a user."""
    user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if user:
        return {"username": user.username, "display_name": user.display_name}
    return {"username": None, "display_name": None}


@router.get("/questions", response_model=List[QuestionOut])
def get_questions(db: Session = Depends(deps.get_db), skip: int = 0, limit: int = 50) -> Any:
    questions = db.query(QuestionModel).order_by(QuestionModel.created_at.desc()).offset(skip).limit(limit).all()
    result = []
    for q in questions:
        answers = []
        for a in q.answers:
            answers.append({**a.__dict__, "author_name": _get_name(db, a.author_id), "author_role": _get_role(db, a.author_id)})
        result.append({**q.__dict__, "author_name": _get_name(db, q.author_id), "author_role": _get_role(db, q.author_id), "answers": answers})
    return result


@router.post("/questions", response_model=QuestionOut)
def create_question(
    q_in: QuestionCreate,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    q = QuestionModel(author_id=current_user.id, text=q_in.text)
    db.add(q)
    db.commit()
    db.refresh(q)
    return {**q.__dict__, "author_name": _get_name(db, q.author_id), "author_role": _get_role(db, q.author_id), "answers": []}


@router.post("/questions/{question_id}/answers", response_model=AnswerOut)
def answer_question(
    question_id: int,
    a_in: AnswerCreate,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    a = AnswerModel(question_id=question_id, author_id=current_user.id, text=a_in.text)
    db.add(a)
    db.commit()
    db.refresh(a)
    return {**a.__dict__, "author_name": _get_name(db, a.author_id), "author_role": _get_role(db, a.author_id)}


# ── Tournaments ───────────────────────────────────────────────────────────────

@router.post("/tournaments/approve")
def approve_tournament(
    tournament_id: int,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    from app.models.v4_extensions import Tournament
    if current_user.role.name not in ["Admin", "Super Admin"]:
        raise HTTPException(status_code=403, detail="Not authorized")
        
    tournament = db.query(Tournament).filter(Tournament.id == tournament_id).first()
    if not tournament:
        raise HTTPException(status_code=404, detail="Tournament not found")
        
    # Create Chat Room
    room = ChatRoom(name=f"Tournament: {tournament.name[:20]}", description=f"Chat for {tournament.name}", icon="emoji_events", is_public=True)
    db.add(room)
    db.flush()
    tournament.chat_room_id = room.id
    db.commit()
    return {"message": "Tournament chat room created"}

# ── AI Support ──────────────────────────────────────────────────────────────────
from pydantic import BaseModel
class AIQuery(BaseModel):
    query: str

@router.post("/ai/ask")
def ask_ai(
    query_in: AIQuery,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    from app.core.ai_router import IntelligentRouter
    ai_router = IntelligentRouter(db)
    session_id = f"api_user_{current_user.id}"
    # Automatically prepend @support so the router handles it
    is_handled, ai_text = ai_router.process_message(current_user.id, f"@support {query_in.query}", session_id)
    return {"response": ai_text if is_handled else "Sorry, I could not understand your query."}


# ── Chat ──────────────────────────────────────────────────────────────────────

def _seed_default_rooms(db: Session):
    """Ensure default chat rooms exist."""
    defaults = [
        {"name": "General", "description": "Public town chat", "icon": "chat", "is_public": True},
        {"name": "Announcements", "description": "Official updates & alerts", "icon": "campaign", "is_public": True},
        {"name": "Government Updates", "description": "Info from local authorities", "icon": "account_balance", "is_public": True},
        {"name": "Marketplace", "description": "Buy and sell discussions", "icon": "shopping_bag", "is_public": True},
        {"name": "Events", "description": "Upcoming events & meetups", "icon": "event", "is_public": True},
        {"name": "Help & Support", "description": "Ask for help from the community", "icon": "help", "is_public": True},
    ]
    for d in defaults:
        exists = db.query(ChatRoom).filter(ChatRoom.name == d["name"]).first()
        if not exists:
            db.add(ChatRoom(**d))
    db.commit()


@router.get("/chat/rooms", response_model=List[ChatRoomOut])
def get_chat_rooms(db: Session = Depends(deps.get_db)) -> Any:
    _seed_default_rooms(db)
    return db.query(ChatRoom).filter(ChatRoom.is_public == True).all()

from pydantic import BaseModel
class ChatRoomCreate(BaseModel):
    name: str
    description: Optional[str] = None
    icon: Optional[str] = "chat"

@router.post("/chat/rooms", response_model=ChatRoomOut)
def create_chat_room(
    room_in: ChatRoomCreate,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    """Create a custom chat room (Admins only)."""
    if current_user.role.name not in ["Super Admin", "Admin", "Moderator", "Government", "Police", "Municipality"]:
        raise HTTPException(status_code=403, detail="Not authorized to create chat rooms")
        
    room = ChatRoom(
        name=room_in.name,
        description=room_in.description,
        icon=room_in.icon,
        is_public=True
    )
    db.add(room)
    db.commit()
    db.refresh(room)
    return room


@router.get("/chat/rooms/{room_id}/messages", response_model=List[ChatMessageOut])
def get_messages(
    room_id: int,
    db: Session = Depends(deps.get_db),
    limit: int = 50,
) -> Any:
    msgs = (
        db.query(ChatMessage)
        .filter(ChatMessage.room_id == room_id, ChatMessage.is_deleted == False)
        .order_by(ChatMessage.created_at.desc())
        .limit(limit)
        .all()
    )
    
    if not msgs:
        return []

    # Optimize N+1 queries by bulk fetching users and profiles
    sender_ids = {m.sender_id for m in msgs}
    users = db.query(UserModel).filter(UserModel.id.in_(sender_ids)).all()
    profiles = db.query(ProfileModel).filter(ProfileModel.user_id.in_(sender_ids)).all()
    
    user_map = {u.id: u for u in users}
    profile_map = {p.user_id: p for p in profiles}

    result = []
    for m in reversed(msgs):
        user = user_map.get(m.sender_id)
        profile = profile_map.get(m.sender_id)
        
        username = user.username if user else None
        display_name = user.display_name if user else None
        role_name = user.role.name if user and user.role else "User"
        
        sender_name = "Anonymous"
        if display_name:
            sender_name = display_name
        elif username:
            sender_name = f"@{username}"
        elif profile:
            name = f"{profile.first_name or ''} {profile.last_name or ''}".strip()
            if name:
                sender_name = name

        result.append({
            **m.__dict__,
            "sender_name": sender_name,
            "sender_role": role_name,
            "sender_avatar": profile.avatar_url if profile and profile.avatar_url else None,
            "username": username,
            "display_name": display_name,
            "mentions": m.mentions or [],
            "reactions": m.reactions or {},
            "image_urls": m.image_urls or [],
            "video_urls": m.video_urls or [],
            "file_urls": m.file_urls or [],
            "translated_text": m.translated_text or {}
        })
    return result

@router.post("/chat/rooms/{room_id}/messages", response_model=ChatMessageOut)
def send_message(
    room_id: int,
    msg_in: ChatMessageCreate,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    room = db.query(ChatRoom).filter(ChatRoom.id == room_id).first()
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")
        
    is_official = room.name in ["Announcements", "Government Updates"]
    if is_official and current_user.role.name not in ["Super Admin", "Admin", "Moderator", "Government", "Police", "Municipality"]:
        raise HTTPException(status_code=403, detail="Only administrators can post in this room")
    import re as _re
    mentions = []
    if msg_in.content:
        mentions = _re.findall(r'@(\w+)', msg_in.content)
        
    msg = ChatMessage(
        room_id=room_id,
        sender_id=current_user.id,
        content=msg_in.content,
        reply_to_id=msg_in.reply_to_id,
        mentions=mentions,
        is_voice_note=msg_in.is_voice_note,
        audio_url=msg_in.audio_url,
        image_urls=msg_in.image_urls,
        video_urls=msg_in.video_urls,
        file_urls=msg_in.file_urls
    )
    db.add(msg)
    db.commit()
    db.refresh(msg)
    user_info = _get_user_info(db, current_user.id)
    
    response = {
        **msg.__dict__,
        "sender_name": _get_name(db, current_user.id),
        "sender_role": _get_role(db, current_user.id),
        "sender_avatar": current_user.profile.avatar_url if current_user.profile else None,
        "username": user_info["username"],
        "display_name": user_info["display_name"],
        "mentions": mentions,
        "reactions": msg.reactions or {},
        "image_urls": msg.image_urls or [],
        "video_urls": msg.video_urls or [],
        "file_urls": msg.file_urls or [],
        "translated_text": msg.translated_text or {}
    }
    
    # Auto AI/Bot Responses for System Mentions
    if mentions:
        try:
            from app.core.ai_router import IntelligentRouter
            ai_router = IntelligentRouter(db)
            session_id = f"room_{room_id}_{current_user.id}"
            is_handled, ai_text = ai_router.process_message(current_user.id, msg_in.content, session_id)
            
            if is_handled and ai_text:
                system_user = db.query(UserModel).filter(UserModel.username == "system").first()
                if not system_user:
                    from app.models.user import Role
                    role = db.query(Role).filter(Role.name == "Super Admin").first()
                    system_user = UserModel(
                        username="system", email="system@myharur.com", hashed_password="pw",
                        role_id=role.id if role else None, is_active=True
                    )
                    db.add(system_user)
                    db.commit()
                    db.refresh(system_user)
                
                bot_msg = ChatMessage(room_id=room_id, sender_id=system_user.id, content=ai_text, reply_to_id=msg.id)
                db.add(bot_msg)
                db.commit()
                db.refresh(bot_msg)
                
                # We also need to emit the bot's message! This is handled below alongside the user's message.
                import asyncio
                from app.main import sio
                
                bot_response_dict = {
                    **bot_msg.__dict__,
                    "sender_name": "Intelligent Assistant",
                    "sender_role": "AI Bot",
                    "sender_avatar": None,
                    "username": "system",
                    "display_name": "Intelligent Assistant",
                    "reactions": {},
                    "mentions": [],
                    "image_urls": [], "video_urls": [], "file_urls": [], "translated_text": {}
                }
                
                async def broadcast_bot():
                    await asyncio.sleep(1) # simulate typing
                    await sio.emit('new_message', bot_response_dict, room=f'chat_room_{room_id}')
                
                try:
                    loop = asyncio.get_running_loop()
                    loop.create_task(broadcast_bot())
                except RuntimeError:
                    pass # Not in an async loop context
                    
        except Exception as e:
            print(f"REST API AI routing error: {e}")
            
        # Create notifications for actual users tagged
        for m_tag in mentions:
            tagged_user = db.query(UserModel).filter(UserModel.username.ilike(m_tag)).first()
            if tagged_user and tagged_user.id != current_user.id:
                from app.models.system import NotificationQueue
                notif = NotificationQueue(
                    user_id=tagged_user.id,
                    title="You were mentioned in a chat",
                    message=f"{_get_name(db, current_user.id)} mentioned you in {room.name}: {msg_in.content[:50]}...",
                    status="unread",
                    priority="High"
                )
                db.add(notif)
        db.commit()
    # Broadcast to Socket.IO
    import asyncio
    try:
        from app.main import sio
        async def _broadcast():
            await sio.emit("new_message", response, room=f"chat_room_{room_id}")
        
        try:
            loop = asyncio.get_running_loop()
            loop.create_task(_broadcast())
        except RuntimeError:
            asyncio.run(_broadcast())
    except Exception as e:
        print(f"Failed to broadcast REST message: {e}")
            
    return response

@router.delete('/chat/messages/{message_id}')
def delete_chat_message(
    message_id: int,
    reason: Optional[str] = Query(None),
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    message = db.query(ChatMessage).filter(ChatMessage.id == message_id).first()
    if not message:
        raise HTTPException(status_code=404, detail='Message not found')
        
    is_admin = current_user.role.name in ['Admin', 'Super Admin']
    if message.sender_id != current_user.id and not is_admin:
        raise HTTPException(status_code=403, detail='Not authorized to delete this message')
        
    from sqlalchemy.sql import func
    message.is_deleted = True
    message.deleted_at = func.now()
    if is_admin and message.sender_id != current_user.id:
        message.deleted_by_admin = True
        message.delete_reason = reason or 'Violation of community guidelines'
        
    db.commit()
    return {'message': 'Message deleted'}
