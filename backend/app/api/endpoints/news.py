from typing import Any, List, Optional
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime, timedelta

from app.api import deps
from app.schemas.news import News, NewsCreate, NewsApprove
from app.models.news import News as NewsModel
from app.models.user import User as UserModel, Profile as ProfileModel

router = APIRouter()

RSS_FEEDS = [
    "https://news.google.com/rss/search?q=Harur+Tamil+Nadu&hl=en-IN&gl=IN&ceid=IN:en",
    "https://news.google.com/rss/search?q=Dharmapuri+district&hl=en-IN&gl=IN&ceid=IN:en",
    "https://news.google.com/rss/search?q=Tamil+Nadu+news&hl=en-IN&gl=IN&ceid=IN:en",
]

import feedparser
import re
import threading

def strip_html(text):
    if not text:
        return text
    clean = re.compile('<.*?>')
    return re.sub(clean, '', text).replace('&nbsp;', ' ').strip()

def extract_image(text):
    if not text:
        return None
    match = re.search(r'<img[^>]+src="([^">]+)"', text)
    if match:
        return match.group(1)
    return None

def _geo_priority(title: str, source: str) -> int:
    """Return sort priority: lower = higher priority."""
    text = (title + " " + source).lower()
    if any(k in text for k in ['harur', 'ஹாரூர்']):
        return 0
    if any(k in text for k in ['dharmapuri', 'தர்மபுரி']):
        return 1
    if any(k in text for k in ['tamil nadu', 'tamilnadu', 'தமிழ்நாடு', 'salem', 'krishnagiri', 'tiruvannamalai']):
        return 2
    if any(k in text for k in ['india', 'national']):
        return 3
    return 4  # International


def bg_fetch_news():
    """Background task to fetch RSS, deduplicate, and store in DB."""
    from app.db.session import SessionLocal
    from app.models.user import User as UserModel
    from app.models.news import News as NewsModel
    
    db = SessionLocal()
    try:
        # Find the system news account
        news_user = db.query(UserModel).filter(UserModel.username == 'news').first()
        author_id = news_user.id if news_user else 1

        seen_titles = {n.title.lower()[:50] for n in db.query(NewsModel.title).all() if n.title}

        for rss_url in RSS_FEEDS:
            try:
                feed = feedparser.parse(rss_url)
                for entry in feed.entries[:20]:
                    title = (entry.title or "").strip()
                    title_key = re.sub(r'\W+', '', title.lower())[:50]
                    if title_key in seen_titles:
                        continue
                    seen_titles.add(title_key)

                    try:
                        published_dt = datetime(*entry.published_parsed[:6])
                    except Exception:
                        published_dt = datetime.utcnow()

                    source_name = entry.source.title if hasattr(entry, 'source') else "Google News"
                    img_url = extract_image(entry.get('summary', '') or entry.get('description', ''))
                    content_text = strip_html(entry.get('summary', '') or entry.get('description', '')) or "Read more at the source."

                    news_item = NewsModel(
                        author_id=author_id,
                        title=title,
                        description=content_text[:500],
                        image_url=img_url,
                        created_at=published_dt,
                        is_approved=True,
                    )
                    db.add(news_item)
                db.commit()
            except Exception as e:
                print(f"[News] RSS fetch error ({rss_url}): {e}")
    finally:
        db.close()


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
        priority = _geo_priority(n.title, source) if author == "@news" else -1
        
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
    role = getattr(current_user.role, "name", None)
    auto_approve = role in ("Admin", "Moderator", "Super Admin")

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
    db.commit()
    db.refresh(news)
    return news


