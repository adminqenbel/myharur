from celery import shared_task
import logging
import asyncio
import aiohttp
from app.db.session import SessionLocal
from app.models.ingestion import NewsSource, CrawlerLog, RawArticle
from app.tasks.ai_processor import process_raw_article, async_process_article
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

        import feedparser
        import re

        feed = feedparser.parse(source.url)
        if not feed.entries:
            raise Exception("Failed to retrieve or parse RSS content")

        source.last_successful_sync = func.now()
        source.failure_count = 0
        db.commit()

        for entry in feed.entries[:20]:
            title = (entry.title or "").strip()
            link = entry.link if hasattr(entry, 'link') else f"{source.url}#{datetime.now().timestamp()}"
            
            # Extract basic text and image
            content = entry.get('summary', '') or entry.get('description', '')
            clean_re = re.compile('<.*?>')
            text = re.sub(clean_re, '', content).replace('&nbsp;', ' ').strip()
            
            img_match = re.search(r'<img[^>]+src="([^">]+)"', content)
            img_url = img_match.group(1) if img_match else None

            # Check for existing
            existing = db.query(RawArticle).filter(RawArticle.original_url == link).first()
            if existing:
                continue

            raw_article = RawArticle(
                source_id=source.id,
                original_url=link,
                extracted_title=title,
                extracted_text=text[:5000],
                status="pending"
            )
            # Store image in json metadata for AI processor
            raw_article.raw_json = {"image_url": img_url, "published": str(entry.get('published', ''))}
            
            db.add(raw_article)
            db.commit()
            db.refresh(raw_article)

            try:
                await async_process_article(raw_article.id)
            except Exception as e:
                logger.error(f"Failed to process article synchronously: {e}")

        log = CrawlerLog(source_id=source.id, status="success", articles_found=len(feed.entries[:20]))
        db.add(log)
        db.commit()

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
            
        fetch_weather.delay()
    finally:
        db.close()

def sync_trigger_crawlers():
    logger.info("Triggering crawlers synchronously (No Celery)...")
    db = SessionLocal()
    try:
        sources = db.query(NewsSource).filter(NewsSource.is_active == True).all()
        for source in sources:
            try:
                asyncio.run(async_crawl_source(source.id))
            except Exception as e:
                logger.error(f"Error in sync crawl: {e}")
                
        try:
            asyncio.run(async_fetch_weather())
        except Exception as e:
            logger.error(f"Error in sync weather: {e}")
    finally:
        db.close()

@shared_task(name="app.tasks.crawler.fetch_weather")
def fetch_weather():
    asyncio.run(async_fetch_weather())

async def async_fetch_weather():
    from app.models.v4_extensions import Weather
    # Harur coordinates
    lat = 12.0628
    lng = 78.4950
    url = f"https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lng}&current=temperature_2m,relative_humidity_2m,wind_speed_10m,precipitation&timezone=Asia%2FKolkata"
    
    async with aiohttp.ClientSession() as session:
        try:
            async with session.get(url, timeout=10) as response:
                if response.status == 200:
                    data = await response.json()
                    current = data.get("current", {})
                    temp = current.get("temperature_2m", 0)
                    hum = current.get("relative_humidity_2m", 0)
                    rain = current.get("precipitation", 0)
                    wind = current.get("wind_speed_10m", 0)
                    
                    condition = "Clear"
                    if rain > 0:
                        condition = "Rain"
                    elif hum > 80:
                        condition = "Cloudy"
                        
                    db = SessionLocal()
                    try:
                        weather = Weather(
                            temperature=temp,
                            condition=condition,
                            humidity=hum,
                            # Optional: you could add rain and wind if columns are added later, but we map to condition for now.
                        )
                        db.add(weather)
                        db.commit()
                    finally:
                        db.close()
        except Exception as e:
            logger.error(f"Failed to fetch weather: {e}")
