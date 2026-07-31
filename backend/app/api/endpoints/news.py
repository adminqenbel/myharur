from typing import Any, List, Optional
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime, timedelta

from app.api import deps
from app.schemas.news import News, NewsCreate, NewsApprove
from app.models.news import News as NewsModel
from app.models.user import User as UserModel, Profile as ProfileModel

router = APIRouter()

from app.tasks.crawler import trigger_crawlers

def trigger_bg_news_fetch():
    """Triggers the Celery pipeline which handles dynamic sources and locations."""
    trigger_crawlers.delay()

def _get_geo_priority_keywords(db: Session) -> dict:
    """Dynamically builds location keywords from the database for sorting priority."""
    from app.models.location import District, Taluk, Town, Village
    keywords = {0: ["harur", "ஹாரூர்"], 1: ["dharmapuri", "தர்மபுரி"], 2: ["tamil nadu", "tamilnadu", "தமிழ்நாடு"]}
    
    # Attempt to fetch from DB
    try:
        taluks = [t.name.lower() for t in db.query(Taluk).all()]
        villages = [v.name.lower() for v in db.query(Village).all()]
        if taluks or villages:
            keywords[0].extend(taluks)
            keywords[0].extend(villages)
    except Exception:
        pass
        
    return keywords

def _geo_priority_dynamic(title: str, source: str, keywords: dict) -> int:
    text = (title + " " + source).lower()
    for priority, words in keywords.items():
        if any(w in text for w in words):
            return priority
    if any(k in text for k in ['india', 'national']):
        return 3
    return 4



def _get_author_name(db: Session, user_id: int) -> str:
    from app.models.user import User as UserModel
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


# ── Endpoints ────────────────────────────────────────────────────────────────

@router.get("/gold-rates")
def get_gold_rates() -> Any:
    """Get the latest cached gold and silver rates."""
    import app.main
    if not hasattr(app.main, 'current_rates'):
        return {"error": "Rates not initialized yet"}
    return app.main.current_rates

@router.get("/")
def read_news(
    db: Session = Depends(deps.get_db),
    skip: int = 0,
    limit: int = 100,
) -> Any:
    """Retrieve approved news from DB (optimized)."""
    db_news_joined = (
        db.query(NewsModel, UserModel, ProfileModel)
        .outerjoin(UserModel, NewsModel.author_id == UserModel.id)
        .outerjoin(ProfileModel, ProfileModel.user_id == UserModel.id)
        .filter(NewsModel.is_approved == True)
        .order_by(NewsModel.created_at.desc())
        .limit(200)  # Limit search space to avoid full table scan
        .all()
    )

    keywords = _get_geo_priority_keywords(db)

    combined_news = []
    for n, u, p in db_news_joined:
        # Resolve author name
        author = "Anonymous"
        if u:
            if u.display_name:
                author = u.display_name
            elif u.username:
                author = f"@{u.username}"
            elif p and (p.first_name or p.last_name):
                author = f"{p.first_name or ''} {p.last_name or ''}".strip() or "Anonymous"

        source = "Local News" if author != "@news" else "Harur News Feed"
        priority = _geo_priority_dynamic(n.title, source, keywords) if author == "@news" else -1
        
        combined_news.append({
            "id": n.id,
            "title": n.title,
            "content": n.description,
            "source": source,
            "url": None,
            "image_url": n.image_url,
            "created_at": n.created_at.isoformat() if n.created_at else None,
            "author_name": author,
            "is_approved": True,
            "geo_priority": priority,
        })

    # Sort: local news first, then by geo priority, then by date
    combined_news.sort(key=lambda x: (
        x.get("geo_priority", 4),
        -(datetime.fromisoformat(x["created_at"]).timestamp() if x.get("created_at") else 0)
    ))

    # Apply pagination and strip geo_priority
    paginated = combined_news[skip : skip + limit]
    for item in paginated:
        item.pop("geo_priority", None)

    return paginated


@router.post("/", response_model=News)
def create_news(
    *,
    db: Session = Depends(deps.get_db),
    news_in: NewsCreate,
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    """Create a new news post. Admins/Moderators are auto-approved."""
    from app.core.rbac import get_user_permissions
    perms = get_user_permissions(db, current_user)
    auto_approve = "Manage News" in perms or "Super Admin" in [r.name for r in current_user.roles]

    news = NewsModel(
        author_id=current_user.id,
        title=news_in.title,
        description=news_in.description,
        image_url=news_in.image_url,
        category_id=news_in.category_id,
        location_name=news_in.location_name,
        location_lat=news_in.location_lat,
        location_lng=news_in.location_lng,
        is_approved=auto_approve,
        verified_by=current_user.id if auto_approve else None,
        verified_at=datetime.utcnow() if auto_approve else None,
    )
    db.add(news)
    db.refresh(news)
    return news
    
from app.models.v4_extensions import Weather

@router.get("/weather")
def get_weather(db: Session = Depends(deps.get_db)) -> Any:
    """Get the latest weather update."""
    latest = db.query(Weather).order_by(Weather.recorded_at.desc()).first()
    if not latest:
        # Fallback if crawler hasn't run
        return {
            "temperature": 28.5,
            "condition": "Clear",
            "humidity": 65,
            "recorded_at": datetime.utcnow().isoformat()
        }
    return {
        "temperature": latest.temperature,
        "condition": latest.condition,
        "humidity": latest.humidity,
        "recorded_at": latest.recorded_at.isoformat() if latest.recorded_at else None
    }



