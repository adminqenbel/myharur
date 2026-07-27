from typing import Any, List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.api import deps
from app.models.community import (
    Listing as ListingModel, JobPosting as JobModel,
    Event as EventModel, Poll as PollModel, PollOption, PollVote,
    Question as QuestionModel, Answer as AnswerModel,
    ChatRoom, ChatMessage
)
from app.models.user import User as UserModel, Profile as ProfileModel
from app.schemas.community import (
    ListingCreate, ListingUpdate, Listing as ListingSchema,
    JobPostingCreate, JobPosting as JobSchema,
    EventCreate, Event as EventSchema,
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
    return db.query(EventModel).filter(EventModel.is_approved == True).order_by(EventModel.event_date).offset(skip).limit(limit).all()


@router.post("/events", response_model=EventSchema)
def create_event(
    event_in: EventCreate,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    event = EventModel(**event_in.dict(), organizer_id=current_user.id)
    db.add(event)
    db.commit()
    db.refresh(event)
    return event


# ── Polls ─────────────────────────────────────────────────────────────────────

def _enrich_poll(poll: PollModel, user_id: Optional[int], db: Session) -> dict:
    voted = None
    if user_id:
        vote = db.query(PollVote).filter(PollVote.poll_id == poll.id, PollVote.user_id == user_id).first()
        if vote:
            voted = vote.option_id
    return {
        "id": poll.id,
        "question": poll.question,
        "is_active": poll.is_active,
        "created_at": poll.created_at,
        "options": poll.options,
        "user_voted_option_id": voted,
    }


@router.get("/polls", response_model=List[PollOut])
def get_polls(db: Session = Depends(deps.get_db), current_user: Optional[UserModel] = Depends(deps.get_current_user)) -> Any:
    polls = db.query(PollModel).filter(PollModel.is_active == True).order_by(PollModel.created_at.desc()).all()
    return [_enrich_poll(p, current_user.id if current_user else None, db) for p in polls]


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


# ── Chat ──────────────────────────────────────────────────────────────────────

def _seed_default_rooms(db: Session):
    """Ensure default chat rooms exist."""
    defaults = [
        {"name": "General", "description": "Public town chat", "icon": "chat"},
        {"name": "Marketplace", "description": "Buy and sell discussions", "icon": "shopping_bag"},
        {"name": "Events", "description": "Upcoming events & meetups", "icon": "event"},
        {"name": "Help & Support", "description": "Ask for help from the community", "icon": "help"},
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
    result = []
    for m in reversed(msgs):
        profile = db.query(ProfileModel).filter(ProfileModel.user_id == m.sender_id).first()
        user_info = _get_user_info(db, m.sender_id)
        result.append({
            **m.__dict__,
            "sender_name": _get_name(db, m.sender_id),
            "sender_role": _get_role(db, m.sender_id),
            "sender_avatar": profile.avatar_url if profile else None,
            "username": user_info["username"],
            "display_name": user_info["display_name"],
            "mentions": m.mentions or [],
        })
    return result


@router.post("/chat/rooms/{room_id}/messages", response_model=ChatMessageOut)
def send_message(
    room_id: int,
    msg_in: ChatMessageCreate,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    import re as _re
    mentions = _re.findall(r'@(\w+)', msg_in.content)
    msg = ChatMessage(
        room_id=room_id,
        sender_id=current_user.id,
        content=msg_in.content,
        mentions=mentions,
    )
    db.add(msg)
    db.commit()
    db.refresh(msg)
    user_info = _get_user_info(db, current_user.id)
    return {
        **msg.__dict__,
        "sender_name": _get_name(db, current_user.id),
        "sender_role": _get_role(db, current_user.id),
        "sender_avatar": current_user.profile.avatar_url if current_user.profile else None,
        "username": user_info["username"],
        "display_name": user_info["display_name"],
        "mentions": mentions,
    }
