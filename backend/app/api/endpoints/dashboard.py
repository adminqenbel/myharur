from typing import Any
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.api import deps
from app.models.user import User
from app.models.shop import Shop
from app.models.news import News
from app.models.emergency import EmergencyRequest

router = APIRouter()

@router.get("/home")
def get_home_dashboard(db: Session = Depends(deps.get_db)) -> Any:
    """Get aggregated data for the home screen dashboard."""
    
    total_citizens = db.query(User).filter(User.is_active == True).count()
    active_shops = db.query(Shop).filter(Shop.is_approved == True).count()
    news_count = db.query(News).filter(News.is_approved == True).count()
    active_emergencies = db.query(EmergencyRequest).filter(EmergencyRequest.status != "resolved").count()
    
    return {
        "town_statistics": {
            "citizens": total_citizens,
            "shops": active_shops,
            "news_reports": news_count,
            "active_emergencies": active_emergencies
        },
        "weather": {
            "condition": "Partly Cloudy",
            "temperature": "29°C",
            "humidity": "65%"
        }
    }
