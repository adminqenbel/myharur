from typing import Any, List, Optional
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime, timedelta

from app.api import deps
from app.schemas.news import News, NewsCreate, NewsApprove
from app.models.news import News as NewsModel
from app.models.user import User as UserModel, Profile as ProfileModel

router = APIRouter()

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


# ── RSS Cache ────────────────────────────────────────────────────────────────
_rss_cache = {
    "data": [],
    "fetched_at": None,
    "lock": threading.Lock(),
}

RSS_CACHE_DURATION = timedelta(hours=2)

RSS_FEEDS = [
    # Harur / Dharmapuri specific
    "https://news.google.com/rss/search?q=Harur+Tamil+Nadu&hl=ta&gl=IN&ceid=IN:ta",
    "https://news.google.com/rss/search?q=Dharmapuri+news&hl=ta&gl=IN&ceid=IN:ta",
    "https://news.google.com/rss/search?q=Harur+OR+Dharmapuri&hl=en-IN&gl=IN&ceid=IN:en",
]

def _fetch_rss() -> list:
    """Fetch RSS from multiple sources, deduplicate, and rank by geo-priority."""
    seen_titles = set()
    result = []

    for rss_url in RSS_FEEDS:
        try:
            feed = feedparser.parse(rss_url)
            for entry in feed.entries[:20]:
                title = (entry.title or "").strip()
                # Deduplication by title similarity
                title_key = re.sub(r'\W+', '', title.lower())[:50]
                if title_key in seen_titles:
                    continue
                seen_titles.add(title_key)

                try:
                    published_dt = datetime(*entry.published_parsed[:6])
                    published_iso = published_dt.isoformat()
                except Exception:
                    published_iso = datetime.now().isoformat()

                source_name = entry.source.title if hasattr(entry, 'source') else "Google News"
                img_url = extract_image(entry.get('summary', '') or entry.get('description', ''))

                content_text = strip_html(
                    entry.get('summary', '') or entry.get('description', '')
                ) or "Read more at the source."

                priority = _geo_priority(title, source_name)

                result.append({
                    "id": None,
                    "title": title,
                    "content": content_text[:500],
                    "source": source_name,
                    "url": entry.link,
                    "image_url": img_url,
                    "created_at": published_iso,
                    "author_name": None,
                    "is_approved": True,
                    "geo_priority": priority,
                })
        except Exception as e:
            print(f"[News] RSS fetch error ({rss_url}): {e}")

    # Sort by geo priority first, then by date descending
    result.sort(key=lambda x: (x["geo_priority"], -(datetime.fromisoformat(x["created_at"]).timestamp() if x["created_at"] else 0)))
    return result


def _get_cached_rss() -> list:
    """Return cached RSS data, refreshing if stale (> 2 hours)."""
    with _rss_cache["lock"]:
        now = datetime.now()
        if _rss_cache["fetched_at"] is None or (now - _rss_cache["fetched_at"]) > RSS_CACHE_DURATION:
            _rss_cache["data"] = _fetch_rss()
            _rss_cache["fetched_at"] = now
        return list(_rss_cache["data"])


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

@router.get("/")
def read_news(
    db: Session = Depends(deps.get_db),
    skip: int = 0,
    limit: int = 100,
) -> Any:
    """Retrieve approved news from DB (prioritized) + cached RSS feed (geo-ranked)."""
    # Fetch approved DB news (local news, always shown first)
    db_news = (
        db.query(NewsModel)
        .filter(NewsModel.is_approved == True)
        .order_by(NewsModel.created_at.desc())
        .offset(skip).limit(limit).all()
    )

    combined_news = []
    for n in db_news:
        combined_news.append({
            "id": n.id,
            "title": n.title,
            "content": n.description,
            "source": "Local News",
            "url": None,
            "image_url": n.image_url,
            "created_at": n.created_at.isoformat() if n.created_at else None,
            "author_name": _get_author_name(db, n.author_id),
            "is_approved": True,
            "geo_priority": -1,  # Local news is always highest priority
        })

    # Get geo-ranked RSS news
    rss_news = _get_cached_rss()
    combined_news.extend(rss_news)

    # Sort: local news first, then by geo priority, then by date
    combined_news.sort(key=lambda x: (
        x.get("geo_priority", 4),
        -(datetime.fromisoformat(x["created_at"]).timestamp() if x.get("created_at") else 0)
    ))

    # Remove geo_priority from output
    for item in combined_news:
        item.pop("geo_priority", None)

    return combined_news


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


