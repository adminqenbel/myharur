from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.api import deps
from app.schemas.news import News, NewsCreate
from app.models.news import News as NewsModel
from app.models.user import User as UserModel

router = APIRouter()

import feedparser
from datetime import datetime
import re

def strip_html(text):
    if not text:
        return text
    clean = re.compile('<.*?>')
    return re.sub(clean, '', text).replace('&nbsp;', ' ')

@router.get("/")
def read_news(
    db: Session = Depends(deps.get_db),
    skip: int = 0,
    limit: int = 100,
) -> Any:
    """
    Retrieve news from DB and live RSS.
    """
    # Fetch from DB
    db_news = db.query(NewsModel).filter(NewsModel.is_approved == True).order_by(NewsModel.created_at.desc()).offset(skip).limit(limit).all()
    
    # Format DB news
    combined_news = []
    for n in db_news:
        combined_news.append({
            "id": n.id,
            "title": n.title,
            "content": n.content,
            "source": "Local News",
            "url": None,
            "created_at": n.created_at.isoformat() if n.created_at else None
        })

    # Fetch live RSS from Google News
    try:
        rss_url = "https://news.google.com/rss/search?q=Dharmapuri+OR+Harur&hl=en-IN&gl=IN&ceid=IN:en"
        feed = feedparser.parse(rss_url)
        for entry in feed.entries[:15]: # Top 15 articles
            # parse date
            try:
                published_dt = datetime(*entry.published_parsed[:6])
                published_iso = published_dt.isoformat()
            except:
                published_iso = datetime.now().isoformat()
                
            combined_news.append({
                "id": None,
                "title": entry.title,
                "content": strip_html(entry.description) if hasattr(entry, 'description') else "Read more at the source.",
                "source": entry.source.title if hasattr(entry, 'source') else "Google News",
                "url": entry.link,
                "created_at": published_iso
            })
    except Exception as e:
        print("RSS fetch error:", e)
        pass

    # Sort combined by date descending
    combined_news.sort(key=lambda x: x["created_at"] or "", reverse=True)
    return combined_news

@router.post("/", response_model=News)
def create_news(
    *,
    db: Session = Depends(deps.get_db),
    news_in: NewsCreate,
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    """
    Create new news.
    """
    news = NewsModel(
        author_id=current_user.id,
        **news_in.dict()
    )
    db.add(news)
    db.commit()
    db.refresh(news)
    return news
