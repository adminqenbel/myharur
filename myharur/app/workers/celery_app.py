from celery import Celery
from app.config import get_settings

settings = get_settings()

celery_app = Celery(
    "myharur",
    broker=settings.redis_url,
    backend=settings.redis_url,
    include=[
        "app.workers.news_crawler"
    ]
)

celery_app.conf.beat_schedule = {
    "crawl-news": {
        "task": "app.workers.news_crawler.crawl_all_sources",
        "schedule": 7200.0
    }
}

celery_app.conf.task_serializer = "json"
celery_app.conf.result_serializer = "json"
celery_app.conf.accept_content = ["json"]
celery_app.conf.task_track_started = True
