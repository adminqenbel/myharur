from typing import Any, List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.api import deps
from app.models.marketplace import MarketplaceListing as MarketplaceModel
from app.models.user import User as UserModel
from app.schemas.marketplace import MarketplaceListingCreate, MarketplaceListingUpdate, MarketplaceListing

router = APIRouter()

@router.get("/", response_model=List[MarketplaceListing])
def get_listings(
    db: Session = Depends(deps.get_db),
    type: Optional[str] = Query(None, description="business, community_used, community_new, jobs, rental"),
    skip: int = 0, limit: int = 50,
) -> Any:
    q = db.query(MarketplaceModel).filter(MarketplaceModel.status == "active")
    if type:
        q = q.filter(MarketplaceModel.type == type)
    return q.order_by(MarketplaceModel.created_at.desc()).offset(skip).limit(limit).all()

@router.post("/", response_model=MarketplaceListing)
def create_listing(
    listing_in: MarketplaceListingCreate,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    if listing_in.type not in ["business", "community_used", "community_new", "jobs", "rental"]:
        raise HTTPException(status_code=400, detail="Invalid listing type")
        
    listing = MarketplaceModel(**listing_in.model_dump(), user_id=current_user.id)
    db.add(listing)
    db.commit()
    db.refresh(listing)
    return listing

@router.put("/{listing_id}/sold")
def mark_sold(
    listing_id: int,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    listing = db.query(MarketplaceModel).filter(MarketplaceModel.id == listing_id).first()
    if not listing or listing.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Listing not found or not yours")
    listing.status = "sold"
    db.commit()
    return {"message": "Marked as sold"}
