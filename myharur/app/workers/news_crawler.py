import redis
from app.workers.celery_app import celery_app
from app.config import get_settings

settings = get_settings()

@celery_app.task(name="app.workers.news_crawler.crawl_all_sources")
def crawl_all_sources():
    """Distributed task for crawling news sources with Redis lock."""
    r = redis.Redis.from_url(settings.redis_url)
    lock = r.lock("lock:news_crawler", timeout=1800)
    
    if not lock.acquire(blocking=False):
        return {"status": "skipped", "reason": "Crawler already running elsewhere"}
    
    try:
        # Crawling logic goes here
        return {"status": "success", "crawled_count": 0}
    finally:
        try:
            lock.release()
        except redis.exceptions.LockError:
            pass
