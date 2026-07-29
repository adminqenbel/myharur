from celery import shared_task
import logging
from app.db.session import SessionLocal
from app.models.ingestion import RawArticle
from app.models.news import News, NewsCategory
from sqlalchemy.orm import Session

logger = logging.getLogger(__name__)

@shared_task(name="app.tasks.ai_processor.process_raw_article")
def process_raw_article(raw_article_id: int):
    """
    AI Processing Pipeline for a raw article.
    Cleans, extracts metadata, checks duplicates, classifies, and publishes.
    """
    logger.info(f"Processing raw article {raw_article_id}...")
    db = SessionLocal()
    try:
        article = db.query(RawArticle).filter(RawArticle.id == raw_article_id).first()
        if not article or article.status != "pending":
            return

        # 1. Content Cleaner & Metadata Extractor (MOCK)
        cleaned_text = article.extracted_text
        title = article.extracted_title

        # 2. Duplicate Detector (MOCK)
        # In reality, compare embeddings or TF-IDF
        is_duplicate = False
        if is_duplicate:
            article.status = "duplicate"
            db.commit()
            return

        # 3. Spam/Fake News Detector (MOCK)
        is_spam = False
        if is_spam:
            article.status = "failed" # or flagged
            db.commit()
            return

        # 4. AI Classifier & Location Detector (MOCK)
        # Assume LLM categorizes this as "Weather" and Location as "Harur"
        category = db.query(NewsCategory).filter(NewsCategory.name == "Weather").first()
        category_id = category.id if category else None
        location_name = "Harur"

        # 5. Priority Engine
        priority = "High" if "rain" in cleaned_text.lower() else "Medium"
        is_breaking = priority == "High"

        # 6. Database Publish
        published_news = News(
            title=title,
            description=cleaned_text[:200] + "...",
            content=cleaned_text,
            category_id=category_id,
            location_name=location_name,
            is_approved=True, # Auto-approved
            is_breaking=is_breaking
        )
        db.add(published_news)
        
        # Mark raw article as processed
        article.status = "processed"
        db.commit()

        # 7. Push Notification (Trigger)
        if priority in ["Critical", "High"]:
            from app.tasks.notifications import push_notification
            push_notification.delay(
                title=f"Breaking News: {title}",
                message=cleaned_text[:100],
                priority=priority
            )

    except Exception as e:
        logger.error(f"Error processing article {raw_article_id}: {e}")
        db.rollback()
    finally:
        db.close()
