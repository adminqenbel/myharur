from typing import List, Any, Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from app.api import deps
from app.models.user import User, Profile
from app.models.gamification import UserReputation

router = APIRouter()

@router.get("/")
def get_leaderboard(
    category: Optional[str] = Query("community", description="Category: community, emergency, volunteer, business, government"),
    timeframe: Optional[str] = Query("all_time", description="Timeframe: weekly, monthly, yearly, all_time"),
    limit: int = 50,
    db: Session = Depends(deps.get_db)
) -> Any:
    """Get the community leaderboard."""
    
    query = db.query(UserReputation, User, Profile).join(User, UserReputation.user_id == User.id).join(Profile, User.id == Profile.user_id).filter(User.is_active == True)
    
    if category == "community":
        query = query.order_by(UserReputation.community_score.desc())
    elif category == "emergency":
        query = query.order_by(UserReputation.emergency_score.desc())
    elif category == "volunteer":
        query = query.order_by(UserReputation.volunteer_score.desc())
    elif category == "business":
        query = query.order_by(UserReputation.business_score.desc())
    elif category == "government":
        query = query.order_by(UserReputation.government_trust_score.desc())
    else:
        query = query.order_by(UserReputation.reputation_score.desc())
        
    results = query.limit(limit).all()
    
    leaderboard = []
    import json
    for idx, (rep, user, p) in enumerate(results):
        leaderboard.append({
            "rank": idx + 1,
            "user_id": user.id,
            "username": user.username,
            "display_name": user.display_name,
            "avatar_url": p.avatar_url,
            "reputation_score": rep.reputation_score,
            "tier_badge": rep.tier_badge,
            "verification_level": rep.verification_level,
            "achievements": json.loads(rep.achievements) if rep.achievements else [],
            
            # Category specific scores
            "community_score": rep.community_score,
            "emergency_score": rep.emergency_score,
            "volunteer_score": rep.volunteer_score,
            "business_score": rep.business_score
        })
        
    return leaderboard

@router.get("/me")
def get_my_leaderboard_status(db: Session = Depends(deps.get_db), current_user: User = Depends(deps.get_current_user)) -> Any:
    """Get the current user's leaderboard status and rank."""
    rep = db.query(UserReputation).filter(UserReputation.user_id == current_user.id).first()
    if not rep:
        return {}
        
    # Calculate rank based on global reputation
    rank = db.query(UserReputation).filter(UserReputation.reputation_score > rep.reputation_score).count() + 1
    
    import json
    return {
        "rank": rank,
        "reputation_score": rep.reputation_score,
        "tier_badge": rep.tier_badge,
        "verification_level": rep.verification_level,
        "achievements": json.loads(rep.achievements) if rep.achievements else [],
        "community_score": rep.community_score,
        "emergency_score": rep.emergency_score,
        "volunteer_score": rep.volunteer_score,
        "business_score": rep.business_score
    }
