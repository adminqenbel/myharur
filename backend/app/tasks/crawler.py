from celery import shared_task
import logging
from app.db.session import SessionLocal
from app.models.ingestion import NewsSource, CrawlerLog, RawArticle
from app.tasks.ai_processor import process_raw_article
from datetime import datetime
from sqlalchemy.sql import func

logger = logging.getLogger(__name__)

@shared_task(name="app.tasks.crawler.trigger_crawlers")
def trigger_crawlers():
    """
    Finds active news sources that are due for a refresh and triggers a crawl.
    """
    logger.info("Triggering crawlers...")
    db = SessionLocal()
    try:
        # Get all active sources
        sources = db.query(NewsSource).filter(NewsSource.is_active == True).all()
        for source in sources:
            # We would normally check refresh_interval here, but for simplicity we trigger
            crawl_source.delay(source.id)
    finally:
        db.close()

@shared_task(name="app.tasks.crawler.crawl_source")
def crawl_source(source_id: int):
    """
    Crawls a specific source based on its type.
    """
    logger.info(f"Crawling source {source_id}...")
    db = SessionLocal()
    try:
        source = db.query(NewsSource).filter(NewsSource.id == source_id).first()
        if not source:
            return

        # --- CRAWLING LOGIC MOCK ---
        # Depending on source.source_type (rss, gov, html), we'd fetch data here.
        # Let's simulate a successful crawl finding 2 articles.
        
        log = CrawlerLog(source_id=source.id, status="success", articles_found=2)
        db.add(log)
        
        source.last_successful_sync = func.now()
        source.failure_count = 0
        db.commit()

        # Simulate fetching an article
        article_url = f"https://example.com/news/{datetime.now().timestamp()}"
        raw_article = RawArticle(
            source_id=source.id,
            original_url=article_url,
            raw_html="<h1>Simulated Breaking News</h1><p>Heavy rain in Harur.</p>",
            extracted_title="Simulated Breaking News",
            extracted_text="Heavy rain in Harur.",
            status="pending"
        )
        db.add(raw_article)
        db.commit()
        db.refresh(raw_article)

        # Trigger AI Pipeline for this article
        process_raw_article.delay(raw_article.id)

    except Exception as e:
        logger.error(f"Error crawling source {source_id}: {e}")
        # Log failure
        source = db.query(NewsSource).filter(NewsSource.id == source_id).first()
        if source:
            source.failure_count += 1
            log = CrawlerLog(source_id=source.id, status="failed", error_message=str(e))
            db.add(log)
            db.commit()
    finally:
        db.close()
