from typing import List, Any
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.api import deps
from app.models.user import User, Profile

router = APIRouter()

def get_rank_title(points: int) -> str:
    if points < 50: return "Citizen"
    if points < 150: return "Trusted Citizen"
    if points < 300: return "Volunteer"
    if points < 500: return "Community Leader"
    if points < 1000: return "Town Guardian"
    if points < 2000: return "Harur Legend"
    if points < 3000: return "People's Hero"
    return "Harur Legend" # Top tier

@router.get("/")
def get_leaderboard(db: Session = Depends(deps.get_db), limit: int = 50) -> Any:
    """Get the community leaderboard."""
    profiles = db.query(Profile).order_by(Profile.reward_points.desc()).limit(limit).all()
    
    leaderboard = []
    for idx, p in enumerate(profiles):
        user = p.user
        if not user or not user.is_active:
            continue
            
        leaderboard.append({
            "rank": idx + 1,
            "user_id": user.id,
            "username": user.username,
            "display_name": user.display_name,
            "avatar_url": p.avatar_url,
            "reward_points": p.reward_points,
            "rank_title": get_rank_title(p.reward_points),
            "volunteer_hours": p.volunteer_hours,
            "emergency_score": p.emergency_score,
            "news_posted": p.news_posted
        })
        
    return leaderboard

@router.get("/me")
def get_my_leaderboard_status(db: Session = Depends(deps.get_db), current_user: User = Depends(deps.get_current_active_user)) -> Any:
    """Get the current user's leaderboard status and rank."""
    profile = db.query(Profile).filter(Profile.user_id == current_user.id).first()
    if not profile:
        return {}
        
    # Calculate rank
    rank = db.query(Profile).filter(Profile.reward_points > profile.reward_points).count() + 1
    
    return {
        "rank": rank,
        "reward_points": profile.reward_points,
        "rank_title": get_rank_title(profile.reward_points),
        "volunteer_hours": profile.volunteer_hours,
        "emergency_score": profile.emergency_score,
        "news_posted": profile.news_posted
    }
