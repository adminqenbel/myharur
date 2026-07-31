from typing import Any, List, Optional
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel

from app.api import deps
from app.models.gamification import UserReputation
from app.models.user import User as UserModel

router = APIRouter()

class ReputationOut(BaseModel):
    user_id: int
    
    trust_score: float
    community_score: float
    contribution_score: float
    emergency_score: float
    volunteer_score: float
    business_score: float
    government_trust_score: float
    
    upvotes: int
    downvotes: int
    helpful_answers: int
    events_attended: int
    news_reported: int
    emergencies_responded: int
    
    reputation_score: float
    tier_badge: str
    verification_level: str
    achievements: str

    class Config:
        from_attributes = True

def _calculate_score_and_tier(rep: UserReputation):
    # Calculate detailed scores
    rep.community_score = (rep.upvotes * 1.5) - (rep.downvotes * 1.0) + (rep.events_attended * 2.0)
    rep.contribution_score = (rep.helpful_answers * 3.0) + (rep.news_reported * 5.0)
    rep.emergency_score = rep.emergencies_responded * 10.0
    
    # Global Reputation Score (Weighted Sum)
    base_score = rep.community_score + rep.contribution_score + rep.emergency_score + rep.volunteer_score + rep.business_score + rep.government_trust_score
    rep.reputation_score = max(0.0, base_score)
    
    # Tier mapping based on advanced tiers
    if rep.reputation_score >= 10000:
        rep.tier_badge = "Legend"
    elif rep.reputation_score >= 5000:
        rep.tier_badge = "Elite"
    elif rep.reputation_score >= 3000:
        rep.tier_badge = "Emerald"
    elif rep.reputation_score >= 2000:
        rep.tier_badge = "Ruby"
    elif rep.reputation_score >= 1000:
        rep.tier_badge = "Diamond"
    elif rep.reputation_score >= 500:
        rep.tier_badge = "Platinum"
    elif rep.reputation_score >= 250:
        rep.tier_badge = "Gold"
    elif rep.reputation_score >= 100:
        rep.tier_badge = "Silver"
    else:
        rep.tier_badge = "Bronze"
        
    # Achievements logic check
    import json
    achievements = json.loads(rep.achievements) if rep.achievements else []
    if rep.helpful_answers >= 1000 and "1000 Helpful Votes" not in achievements:
        achievements.append("1000 Helpful Votes")
    if rep.news_reported >= 100 and "100 News" not in achievements:
        achievements.append("100 News")
    if rep.emergencies_responded >= 1 and "Emergency responder" not in achievements:
        achievements.append("Emergency responder")
        
    rep.achievements = json.dumps(achievements)

@router.get("/me", response_model=ReputationOut)
def get_my_reputation(
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    rep = db.query(UserReputation).filter(UserReputation.user_id == current_user.id).first()
    if not rep:
        rep = UserReputation(user_id=current_user.id)
        db.add(rep)
        db.commit()
        db.refresh(rep)
    
    _calculate_score_and_tier(rep)
    db.commit()
    return rep

@router.get("/{user_id}", response_model=ReputationOut)
def get_user_reputation(
    user_id: int,
    db: Session = Depends(deps.get_db),
) -> Any:
    rep = db.query(UserReputation).filter(UserReputation.user_id == user_id).first()
    if not rep:
        return ReputationOut(
            user_id=user_id,
            trust_score=0.0, community_score=0.0, contribution_score=0.0, 
            emergency_score=0.0, volunteer_score=0.0, business_score=0.0, government_trust_score=0.0,
            upvotes=0, downvotes=0, helpful_answers=0, events_attended=0, news_reported=0, emergencies_responded=0,
            reputation_score=0.0, tier_badge="Bronze", verification_level="Citizen", achievements="[]"
        )
    return rep
