from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel

from app.api import deps
from app.models.gamification import UserReputation
from app.models.user import User as UserModel

router = APIRouter()

class ReputationOut(BaseModel):
    user_id: int
    upvotes: int
    downvotes: int
    helpful_answers: int
    events_attended: int
    reputation_score: float
    tier_badge: str

    class Config:
        from_attributes = True

def _calculate_score_and_tier(rep: UserReputation):
    # Score calculation logic (moving average proxy or basic formula)
    base_score = (rep.upvotes * 1.5) - (rep.downvotes * 1.0) + (rep.helpful_answers * 3.0) + (rep.events_attended * 2.0)
    rep.reputation_score = max(0.0, base_score)
    
    if rep.reputation_score >= 1000:
        rep.tier_badge = "Platinum"
    elif rep.reputation_score >= 500:
        rep.tier_badge = "Gold"
    elif rep.reputation_score >= 100:
        rep.tier_badge = "Silver"
    else:
        rep.tier_badge = "Bronze"

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
        # Default empty response if not initialized
        return ReputationOut(
            user_id=user_id,
            upvotes=0, downvotes=0, helpful_answers=0, events_attended=0,
            reputation_score=0.0, tier_badge="Bronze"
        )
    return rep
