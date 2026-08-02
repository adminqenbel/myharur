from celery import shared_task
import logging
import asyncio
import aiohttp
from app.db.session import SessionLocal
from app.models.ingestion import RawArticle
from app.models.news import News, NewsCategory
from sqlalchemy.orm import Session
from datetime import datetime

logger = logging.getLogger(__name__)

async def analyze_text_async(text: str):
    """Simulates an asynchronous call to an NLP service for sentiment, summary, and tags."""
    await asyncio.sleep(0.5)
    
    sentiment = "neutral"
    if any(w in text.lower() for w in ["rain", "storm", "accident", "death"]):
        sentiment = "negative"
    elif any(w in text.lower() for w in ["win", "success", "growth", "celebration"]):
        sentiment = "positive"
        
    tags = []
    if "harur" in text.lower():
        tags.append("#Local")
    if sentiment == "negative" and "rain" in text.lower():
        tags.append("#Alert")
        
    abstract = text[:150] + "..." if len(text) > 150 else text
    return {"sentiment": sentiment, "tags": tags, "abstract": abstract, "reliability": 0.85}

async def async_process_article(raw_article_id: int):
    logger.info(f"Asynchronously processing raw article {raw_article_id}...")
    db = SessionLocal()
    try:
        article = db.query(RawArticle).filter(RawArticle.id == raw_article_id).first()
        if not article or article.status != "pending":
            return

        cleaned_text = article.extracted_text
        title = article.extracted_title

        nlp_result = await analyze_text_async(cleaned_text)
        
        is_duplicate = False # (Mock)
        if is_duplicate:
            article.status = "duplicate"
            db.commit()
            return

        is_spam = nlp_result["reliability"] < 0.3
        if is_spam:
            article.status = "failed"
            db.commit()
            return

        category = db.query(NewsCategory).filter(NewsCategory.name == "General").first()
        category_id = category.id if category else None
        
        tags_str = ",".join(nlp_result["tags"])
        abstract = nlp_result["abstract"]

        priority = "High" if "#Alert" in nlp_result["tags"] else "Medium"
        is_breaking = priority == "High"

        meta = article.raw_json or {}
        img_url = meta.get("image_url")
        published_str = meta.get("published")
        
        # Parse published date or use now
        from dateutil import parser
        try:
            created_at = parser.parse(published_str).replace(tzinfo=None) if published_str else datetime.utcnow()
        except:
            created_at = datetime.utcnow()

        from app.models.user import User
        system_user = db.query(User).filter(User.username == "news").first()
        author_id = system_user.id if system_user else 1

        published_news = News(
            title=title,
            description=abstract,
            content=cleaned_text,
            category_id=category_id,
            location_name="Harur", # fallback
            is_approved=True, 
            is_breaking=is_breaking,
            tags=tags_str,
            image_url=img_url,
            author_id=author_id,
            created_at=created_at
        )
        db.add(published_news)
        
        article.status = "processed"
        db.commit()

        if priority in ["Critical", "High"]:
            from app.tasks.notifications import push_notification
            try:
                push_notification(
                    title=f"Breaking News: {title}",
                    message=abstract[:100],
                    priority=priority
                )
            except Exception as e:
                logger.error(f"Failed to push notification: {e}")

    except Exception as e:
        logger.error(f"Error processing article {raw_article_id}: {e}")
        db.rollback()
    finally:
        db.close()

@shared_task(name="app.tasks.ai_processor.process_raw_article")
def process_raw_article(raw_article_id: int):
    asyncio.run(async_process_article(raw_article_id))
