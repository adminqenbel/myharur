from celery import shared_task
import logging
from app.db.session import SessionLocal
from app.models.system import NotificationQueue

logger = logging.getLogger(__name__)

@shared_task(name="app.tasks.notifications.push_notification")
def push_notification(title: str, message: str, priority: str = "normal", user_id: int = None):
    """
    Sends a push notification to users.
    """
    logger.info(f"Sending push notification: {title} (Priority: {priority})")
    db = SessionLocal()
    try:
        # 1. Queue it in database for history/retry
        notification = NotificationQueue(
            user_id=user_id,
            title=title,
            message=message,
            priority=priority,
            status="pending"
        )
        db.add(notification)
        db.commit()

        # 2. Integrate with Firebase Cloud Messaging (FCM) or APNs here
        # fcm.send(title, message, topic="all_users")
        
        # 3. Update status
        notification.status = "sent"
        db.commit()

    except Exception as e:
        logger.error(f"Error sending push notification: {e}")
        # Note: Celery can be configured to retry on failure
    finally:
        db.close()

import random

@shared_task(name="app.tasks.notifications.send_daily_catchy_notification")
def send_daily_catchy_notification():
    """
    Sends a catchy daily notification to encourage app opens.
    """
    messages = [
        {"title": "🌟 Stay Updated!", "message": "Check out the latest local news and events happening around you."},
        {"title": "👋 Hello Dharmapuri!", "message": "See what your community is up to today. Tap to explore!"},
        {"title": "🔥 Trending Now", "message": "Don't miss out on the hottest discussions in the community."},
        {"title": "💼 New Opportunities", "message": "Fresh jobs and marketplace listings just dropped. Take a look!"},
        {"title": "🏆 Top the Leaderboard", "message": "Engage with the community and earn points to climb the ranks!"}
    ]
    selected = random.choice(messages)
    # Sending a broadcast push notification (user_id=None implies broadcast in our simplified system)
    push_notification.delay(title=selected["title"], message=selected["message"], priority="high")

