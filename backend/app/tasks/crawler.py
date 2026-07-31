from celery import shared_task
import logging
import asyncio
import aiohttp
from app.db.session import SessionLocal
from app.models.ingestion import NewsSource, CrawlerLog, RawArticle
from app.tasks.ai_processor import process_raw_article
from datetime import datetime
from sqlalchemy.sql import func
from bs4 import BeautifulSoup

logger = logging.getLogger(__name__)

async def fetch_url(session, url):
    try:
        async with session.get(url, timeout=10) as response:
            if response.status == 200:
                return await response.text()
    except Exception as e:
        logger.error(f"Failed to fetch {url}: {e}")
    return None

async def async_crawl_source(source_id: int):
    logger.info(f"Asynchronously crawling source {source_id}...")
    db = SessionLocal()
    try:
        source = db.query(NewsSource).filter(NewsSource.id == source_id).first()
        if not source:
            return

        async with aiohttp.ClientSession() as session:
            html = await fetch_url(session, source.url)
            if not html:
                raise Exception("Failed to retrieve content")
                
            soup = BeautifulSoup(html, 'html.parser')
            # Extract basic text (simplified logic)
            text = soup.get_text(separator=' ', strip=True)[:2000]
            title = soup.title.string if soup.title else "News Update"

            log = CrawlerLog(source_id=source.id, status="success", articles_found=1)
            db.add(log)
            source.last_successful_sync = func.now()
            source.failure_count = 0
            
            article_url = f"{source.url}#{datetime.now().timestamp()}"
            raw_article = RawArticle(
                source_id=source.id,
                original_url=article_url,
                raw_html=html[:1000], # store subset for example
                extracted_title=title,
                extracted_text=text,
                status="pending"
            )
            db.add(raw_article)
            db.commit()
            db.refresh(raw_article)

            process_raw_article.delay(raw_article.id)

    except Exception as e:
        logger.error(f"Error crawling source {source_id}: {e}")
        source = db.query(NewsSource).filter(NewsSource.id == source_id).first()
        if source:
            source.failure_count += 1
            log = CrawlerLog(source_id=source.id, status="failed", error_message=str(e))
            db.add(log)
            db.commit()
    finally:
        db.close()

@shared_task(name="app.tasks.crawler.crawl_source")
def crawl_source(source_id: int):
    """Celery entrypoint for crawling a source."""
    asyncio.run(async_crawl_source(source_id))

@shared_task(name="app.tasks.crawler.trigger_crawlers")
def trigger_crawlers():
    logger.info("Triggering crawlers...")
    db = SessionLocal()
    try:
        sources = db.query(NewsSource).filter(NewsSource.is_active == True).all()
        for source in sources:
            crawl_source.delay(source.id)
    finally:
        db.close()
