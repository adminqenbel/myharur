from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.api import deps
from app.schemas.news import News, NewsCreate
from app.models.news import News as NewsModel
from app.models.user import User as UserModel

router = APIRouter()

@router.get("/", response_model=List[News])
def read_news(
    db: Session = Depends(deps.get_db),
    skip: int = 0,
    limit: int = 100,
) -> Any:
    """
    Retrieve news.
    """
    news = db.query(NewsModel).filter(NewsModel.is_approved == True).order_by(NewsModel.created_at.desc()).offset(skip).limit(limit).all()
    return news

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
