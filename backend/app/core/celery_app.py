import os
from celery import Celery

# Redis is used as the message broker and result backend
redis_url = os.environ.get("REDIS_URL", "redis://localhost:6379/0")

celery_app = Celery(
    "worker",
    broker=redis_url,
    backend=redis_url,
    include=["app.tasks.crawler", "app.tasks.ai_processor", "app.tasks.notifications"]
)

celery_app.conf.update(
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="Asia/Kolkata",
    enable_utc=True,
    # Celery Beat Schedule
    beat_schedule={
        "run-crawlers-every-2-hours": {
            "task": "app.tasks.crawler.trigger_crawlers",
            "schedule": 7200.0, # 2 hours in seconds
        },
    }
)
