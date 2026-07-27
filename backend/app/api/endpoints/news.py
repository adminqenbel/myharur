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
    return re.sub(clean, '', text).replace('&nbsp;', ' ')

def extract_image(text):
    if not text:
        return None
    match = re.search(r'<img[^>]+src="([^">]+)"', text)
    if match:
        return match.group(1)
    return None


# ── RSS Cache ────────────────────────────────────────────────────────────────
_rss_cache = {
    "data": [],
    "fetched_at": None,
    "lock": threading.Lock(),
}

RSS_CACHE_DURATION = timedelta(hours=2)

def _fetch_rss() -> list:
    """Fetch RSS and return list of news dicts."""
    result = []
    try:
        rss_url = "https://news.google.com/rss/search?q=Dharmapuri+OR+Harur&hl=en-IN&gl=IN&ceid=IN:en"
        feed = feedparser.parse(rss_url)
        for entry in feed.entries[:15]:
            try:
                published_dt = datetime(*entry.published_parsed[:6])
                published_iso = published_dt.isoformat()
            except:
                published_iso = datetime.now().isoformat()

            img_url = extract_image(entry.description) if hasattr(entry, 'description') else None

            result.append({
                "id": None,
                "title": entry.title,
                "content": strip_html(entry.description) if hasattr(entry, 'description') else "Read more at the source.",
                "source": entry.source.title if hasattr(entry, 'source') else "Google News",
                "url": entry.link,
                "image_url": img_url,
                "created_at": published_iso,
                "author_name": None,
                "is_approved": True,
            })
    except Exception as e:
        print("RSS fetch error:", e)
    return result


def _get_cached_rss() -> list:
    """Return cached RSS data, refreshing if stale (>2 hours)."""
    with _rss_cache["lock"]:
        now = datetime.now()
        if _rss_cache["fetched_at"] is None or (now - _rss_cache["fetched_at"]) > RSS_CACHE_DURATION:
            _rss_cache["data"] = _fetch_rss()
            _rss_cache["fetched_at"] = now
        return list(_rss_cache["data"])


def _get_author_name(db: Session, user_id: int) -> str:
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
    """
    Retrieve approved news from DB + cached RSS feed.
    """
    # Fetch approved DB news
    db_news = db.query(NewsModel).filter(NewsModel.is_approved == True).order_by(NewsModel.created_at.desc()).offset(skip).limit(limit).all()

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
        })

    # Get cached RSS news
    rss_news = _get_cached_rss()
    combined_news.extend(rss_news)

    # Sort combined by date descending
    combined_news.sort(key=lambda x: x["created_at"] or "", reverse=True)
    return combined_news


@router.get("/pending")
def get_pending_news(
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    """Get news pending approval (Admin/Moderator/Super Admin only)."""
    role = getattr(current_user.role, "name", None)
    if role not in ("Admin", "Moderator", "Super Admin"):
        raise HTTPException(status_code=403, detail="Not authorized")

    pending = db.query(NewsModel).filter(NewsModel.is_approved == False).order_by(NewsModel.created_at.desc()).all()
    result = []
    for n in pending:
        result.append({
            "id": n.id,
            "title": n.title,
            "content": n.description,
            "image_url": n.image_url,
            "created_at": n.created_at.isoformat() if n.created_at else None,
            "author_name": _get_author_name(db, n.author_id),
            "is_approved": n.is_approved,
        })
    return result


@router.post("/", response_model=News)
def create_news(
    *,
    db: Session = Depends(deps.get_db),
    news_in: NewsCreate,
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    """
    Create a new news post. Defaults to is_approved=False (needs admin review).
    Admin/Moderator/Super Admin posts are auto-approved.
    """
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


@router.put("/{news_id}/approve")
def approve_news(
    news_id: int,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    """Approve a pending news post (Admin/Moderator/Super Admin only)."""
    role = getattr(current_user.role, "name", None)
    if role not in ("Admin", "Moderator", "Super Admin"):
        raise HTTPException(status_code=403, detail="Not authorized")

    news = db.query(NewsModel).filter(NewsModel.id == news_id).first()
    if not news:
        raise HTTPException(status_code=404, detail="News not found")

    news.is_approved = True
    news.verified_by = current_user.id
    news.verified_at = datetime.utcnow()
    db.commit()
    return {"message": "News approved", "id": news_id}


@router.put("/{news_id}/reject")
def reject_news(
    news_id: int,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    """Reject/delete a pending news post (Admin/Moderator/Super Admin only)."""
    role = getattr(current_user.role, "name", None)
    if role not in ("Admin", "Moderator", "Super Admin"):
        raise HTTPException(status_code=403, detail="Not authorized")

    news = db.query(NewsModel).filter(NewsModel.id == news_id).first()
    if not news:
        raise HTTPException(status_code=404, detail="News not found")

    db.delete(news)
    db.commit()
    return {"message": "News rejected and removed", "id": news_id}
