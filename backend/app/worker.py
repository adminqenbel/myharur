from app.core.celery_app import celery_app

# The worker can be started with:
# celery -A app.worker.celery_app worker --loglevel=info
# celery -A app.worker.celery_app beat --loglevel=info
