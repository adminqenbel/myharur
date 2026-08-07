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

# ── Tamil Nadu Relevance Filter ──────────────────────────────────────────────
TN_KEYWORDS = [
    "harur", "dharmapuri", "tamilnadu", "tamil nadu", "salem",
    "krishnagiri", "hosur", "erode", "coimbatore", "madurai",
    "tirunelveli", "trichy", "tiruchirappalli", "vellore", "tiruppur",
    "chennai", "thanjavur", "nagapattinam", "tneb", "tangedco",
    "panchayat", "collector", "district", "dmk", "aiadmk", "mk stalin"
]

LOCAL_KEYWORDS = [
    "harur", "dharmapuri", "krishnagiri", "hosur", "palacode", "pennagaram"
]


def _is_tn_relevant(title: str, text: str) -> bool:
    """Check if article is relevant to Tamil Nadu, prioritising Harur/Dharmapuri."""
    combined = (title + " " + text).lower()
    return any(kw in combined for kw in TN_KEYWORDS)


def _detect_location(title: str, text: str) -> str:
    """Detect primary location from article content."""
    combined = (title + " " + text).lower()
    if "harur" in combined:
        return "Harur"
    if "dharmapuri" in combined:
        return "Dharmapuri"
    if "krishnagiri" in combined:
        return "Krishnagiri"
    if "hosur" in combined:
        return "Hosur"
    if "salem" in combined:
        return "Salem"
    if "chennai" in combined:
        return "Chennai"
    return "Tamil Nadu"


async def analyze_text_async(text: str, title: str = ""):
    """NLP analysis with TN relevance scoring."""
    await asyncio.sleep(0.1)

    combined = (title + " " + text).lower()

    sentiment = "neutral"
    if any(w in combined for w in ["rain", "storm", "accident", "death", "flood", "fire", "disaster"]):
        sentiment = "negative"
    elif any(w in combined for w in ["win", "success", "growth", "celebration", "award", "inauguration"]):
        sentiment = "positive"

    tags = []
    if any(kw in combined for kw in LOCAL_KEYWORDS):
        tags.append("#Local")
    if sentiment == "negative" and any(w in combined for w in ["rain", "flood", "storm"]):
        tags.append("#Alert")
    if "accident" in combined or "death" in combined:
        tags.append("#Alert")
    if "panchayat" in combined or "government" in combined or "tneb" in combined:
        tags.append("#Government")
    if "police" in combined or "crime" in combined:
        tags.append("#Crime")

    abstract = text[:200] + "..." if len(text) > 200 else text
    return {"sentiment": sentiment, "tags": tags, "abstract": abstract, "reliability": 0.85}


async def async_process_article(raw_article_id: int):
    logger.info(f"Asynchronously processing raw article {raw_article_id}...")
    db = SessionLocal()
    try:
        article = db.query(RawArticle).filter(RawArticle.id == raw_article_id).first()
        if not article or article.status != "pending":
            return

        cleaned_text = article.extracted_text or ""
        title = article.extracted_title or ""

        # ── TN Relevance Gate ──
        if not _is_tn_relevant(title, cleaned_text):
            logger.info(f"Article {raw_article_id} not TN-relevant, skipping.")
            article.status = "failed"
            db.commit()
            return

        nlp_result = await analyze_text_async(cleaned_text, title)

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
        # IMPORTANT: Store original source image URL — do NOT download/re-host.
        # The frontend renders the image directly from the news source URL.
        # This saves storage and always shows the most up-to-date version.
        img_url = meta.get("image_url")
        published_str = meta.get("published")

        from dateutil import parser
        try:
            created_at = parser.parse(published_str).replace(tzinfo=None) if published_str else datetime.utcnow()
        except Exception:
            created_at = datetime.utcnow()

        from app.models.user import User
        system_user = db.query(User).filter(User.username == "news").first()
        author_id = system_user.id if system_user else 1

        location_name = _detect_location(title, cleaned_text)

        # Guard against duplicate URLs
        existing = db.query(News).filter(News.source_url == article.original_url).first()
        if existing:
            article.status = "duplicate"
            db.commit()
            return

        published_news = News(
            title=title,
            description=abstract,
            content=cleaned_text,
            category_id=category_id,
            location_name=location_name,
            is_approved=True,
            is_breaking=is_breaking,
            tags=tags_str,
            image_url=img_url,       # Source URL — rendered directly by Flutter
            source_url=article.original_url,
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
