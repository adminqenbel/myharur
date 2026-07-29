from sqlalchemy.orm import Session
from app.models.ingestion import NewsSource, CrawlerLog, RawArticle
from app.schemas.ingestion import NewsSourceCreate, NewsSourceUpdate, CrawlerLogCreate, RawArticleCreate
from typing import List, Optional

def get_news_source(db: Session, source_id: int) -> Optional[NewsSource]:
    return db.query(NewsSource).filter(NewsSource.id == source_id).first()

def get_news_sources(db: Session, skip: int = 0, limit: int = 100) -> List[NewsSource]:
    return db.query(NewsSource).offset(skip).limit(limit).all()

def get_active_news_sources(db: Session) -> List[NewsSource]:
    return db.query(NewsSource).filter(NewsSource.is_active == True).all()

def create_news_source(db: Session, source: NewsSourceCreate) -> NewsSource:
    db_source = NewsSource(**source.dict())
    db.add(db_source)
    db.commit()
    db.refresh(db_source)
    return db_source

def update_news_source(db: Session, source_id: int, source_update: NewsSourceUpdate) -> Optional[NewsSource]:
    db_source = get_news_source(db, source_id)
    if not db_source:
        return None
    
    update_data = source_update.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_source, key, value)
        
    db.commit()
    db.refresh(db_source)
    return db_source

def delete_news_source(db: Session, source_id: int) -> bool:
    db_source = get_news_source(db, source_id)
    if not db_source:
        return False
    db.delete(db_source)
    db.commit()
    return True

def create_crawler_log(db: Session, log: CrawlerLogCreate) -> CrawlerLog:
    db_log = CrawlerLog(**log.dict())
    db.add(db_log)
    db.commit()
    db.refresh(db_log)
    return db_log

def create_raw_article(db: Session, article: RawArticleCreate) -> RawArticle:
    db_article = RawArticle(**article.dict())
    db.add(db_article)
    db.commit()
    db.refresh(db_article)
    return db_article
