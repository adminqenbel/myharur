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
import re

logger = logging.getLogger(__name__)


async def fetch_url(session, url):
    try:
        async with session.get(url, timeout=aiohttp.ClientTimeout(total=15)) as response:
            if response.status == 200:
                return await response.text()
    except Exception as e:
        logger.error(f"Failed to fetch {url}: {e}")
    return None


async def async_crawl_source(source_id: int):
    logger.info(f"Asynchronously crawling source {source_id}...")
    db = SessionLocal()
    source = None
    try:
        source = db.query(NewsSource).filter(NewsSource.id == source_id).first()
        if not source:
            return

        import feedparser

        feed = feedparser.parse(source.url)
        if not feed.entries:
            raise Exception("Failed to retrieve or parse RSS content — no entries found")

        source.last_successful_sync = func.now()
        source.failure_count = 0
        db.commit()

        processed = 0
        for entry in feed.entries[:25]:
            title = (entry.title or "").strip()
            link = entry.link if hasattr(entry, 'link') else f"{source.url}#{datetime.now().timestamp()}"

            # Extract text content
            content = entry.get('summary', '') or entry.get('description', '')
            clean_re = re.compile('<.*?>')
            text = re.sub(clean_re, '', content).replace('&nbsp;', ' ').strip()

            # Extract image URL — try multiple RSS media formats
            img_url = None
            if hasattr(entry, 'media_content') and entry.media_content:
                img_url = entry.media_content[0].get('url')
            elif hasattr(entry, 'media_thumbnail') and entry.media_thumbnail:
                img_url = entry.media_thumbnail[0].get('url')
            elif hasattr(entry, 'enclosures') and entry.enclosures:
                for enc in entry.enclosures:
                    if enc.get('type', '').startswith('image/'):
                        img_url = enc.get('href')
                        break
            if not img_url:
                # Try parsing from HTML content
                img_match = re.search(r'<img[^>]+src="([^">]+)"', content)
                img_url = img_match.group(1) if img_match else None
            if not img_url and hasattr(entry, 'links'):
                for lnk in entry.links:
                    if lnk.get('type', '').startswith('image/'):
                        img_url = lnk.get('href')
                        break

            # Skip if already exists
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
            raw_article.raw_json = {
                "image_url": img_url,
                "published": str(entry.get('published', '')),
                "source_name": source.name,
            }

            db.add(raw_article)
            db.commit()
            db.refresh(raw_article)
            processed += 1

            try:
                await async_process_article(raw_article.id)
            except Exception as e:
                logger.error(f"Failed to process article: {e}")

        log = CrawlerLog(source_id=source.id, status="success", articles_found=processed)
        db.add(log)
        db.commit()
        logger.info(f"Crawled source {source.name}: {processed} new articles")

    except Exception as e:
        logger.error(f"Error crawling source {source_id}: {e}")
        if source:
            try:
                source = db.query(NewsSource).filter(NewsSource.id == source_id).first()
                if source:
                    source.failure_count = (source.failure_count or 0) + 1
                    log = CrawlerLog(source_id=source.id, status="failed", error_message=str(e)[:500])
                    db.add(log)
                    db.commit()
            except Exception as inner_e:
                logger.error(f"Could not log failure: {inner_e}")
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
        logger.info(f"Found {len(sources)} active news sources")
        for source in sources:
            try:
                asyncio.run(async_crawl_source(source.id))
            except Exception as e:
                logger.error(f"Error in sync crawl for source {source.id}: {e}")

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
    url = (
        f"https://api.open-meteo.com/v1/forecast"
        f"?latitude={lat}&longitude={lng}"
        f"&current=temperature_2m,relative_humidity_2m,wind_speed_10m,precipitation,weather_code"
        f"&timezone=Asia%2FKolkata"
    )

    async with aiohttp.ClientSession() as session:
        try:
            async with session.get(url, timeout=aiohttp.ClientTimeout(total=10)) as response:
                if response.status == 200:
                    data = await response.json()
                    current = data.get("current", {})
                    temp = current.get("temperature_2m", 0)
                    hum = current.get("relative_humidity_2m", 0)
                    rain = current.get("precipitation", 0)
                    wind = current.get("wind_speed_10m", 0)
                    code = current.get("weather_code", 0)

                    # WMO weather code to condition
                    if rain > 0 or code in range(51, 82):
                        condition = "Rain"
                    elif code in range(71, 78):
                        condition = "Snow"
                    elif code in [45, 48]:
                        condition = "Foggy"
                    elif code in range(95, 100):
                        condition = "Thunderstorm"
                    elif hum > 80:
                        condition = "Cloudy"
                    elif code in [1, 2, 3]:
                        condition = "Partly Cloudy"
                    else:
                        condition = "Clear"

                    db = SessionLocal()
                    try:
                        weather = Weather(
                            temperature=temp,
                            condition=condition,
                            humidity=hum,
                        )
                        db.add(weather)
                        db.commit()
                        logger.info(f"Weather updated: {temp}°C, {condition}")
                    finally:
                        db.close()
        except Exception as e:
            logger.error(f"Failed to fetch weather: {e}")


def verify_and_seed_news_sources(db) -> int:
    """Verify live RSS feeds and seed them into the database. Returns number seeded."""
    import feedparser
    import socket

    candidate_sources = [
        {
            "name": "NDTV Tamil Nadu",
            "url": "https://feeds.feedburner.com/ndtvnews-south",
            "source_type": "rss",
            "priority": 2,
        },
        {
            "name": "The Hindu Tamil Nadu",
            "url": "https://www.thehindu.com/news/states/tamil-nadu/?service=rss",
            "source_type": "rss",
            "priority": 1,
        },
        {
            "name": "OneIndia Tamil Nadu",
            "url": "https://www.oneindia.com/rss/tamilnadu-news.xml",
            "source_type": "rss",
            "priority": 2,
        },
        {
            "name": "Times of India Chennai",
            "url": "https://timesofindia.indiatimes.com/rssfeeds/-2128839596.cms",
            "source_type": "rss",
            "priority": 3,
        },
        {
            "name": "India Today Tamil Nadu",
            "url": "https://www.indiatoday.in/rss/1206577",
            "source_type": "rss",
            "priority": 2,
        },
        {
            "name": "News18 Tamil Nadu",
            "url": "https://www.news18.com/rss/india/tamil-nadu.xml",
            "source_type": "rss",
            "priority": 2,
        },
        {
            "name": "Dinamalar",
            "url": "https://www.dinamalar.com/rss/news_rss.asp",
            "source_type": "rss",
            "priority": 1,
        },
        {
            "name": "Dinamani",
            "url": "https://www.dinamani.com/all-news/?service=rss",
            "source_type": "rss",
            "priority": 1,
        },
        {
            "name": "Puthiyathalaimurai",
            "url": "https://feeds.feedburner.com/puthiyathalaimurai-news",
            "source_type": "rss",
            "priority": 2,
        },
        {
            "name": "Vikatan",
            "url": "https://www.vikatan.com/rss/news.xml",
            "source_type": "rss",
            "priority": 2,
        },
    ]

    seeded = 0
    for src in candidate_sources:
        # Skip if already seeded
        existing = db.query(NewsSource).filter(NewsSource.url == src["url"]).first()
        if existing:
            continue

        # Verify feed is live (quick parse check)
        try:
            socket.setdefaulttimeout(8)
            feed = feedparser.parse(src["url"])
            if not feed.entries and feed.bozo:
                logger.warning(f"[NewsSeed] Skipping dead feed: {src['name']} ({src['url']})")
                continue
            logger.info(f"[NewsSeed] Verified live: {src['name']} ({len(feed.entries)} entries)")
        except Exception as e:
            logger.warning(f"[NewsSeed] Skipping {src['name']}: {e}")
            continue

        source = NewsSource(
            name=src["name"],
            url=src["url"],
            source_type=src["source_type"],
            priority=src["priority"],
            is_active=True,
            refresh_interval_minutes=120,
            failure_count=0,
        )
        db.add(source)
        seeded += 1

    if seeded > 0:
        db.commit()
        logger.info(f"[NewsSeed] Seeded {seeded} new verified news sources")

    return seeded
