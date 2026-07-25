from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.api import deps
from app.schemas.shop import Shop, ShopCreate
from app.models.shop import Shop as ShopModel
from app.models.user import User as UserModel

router = APIRouter()

@router.get("/", response_model=List[Shop])
def read_shops(
    db: Session = Depends(deps.get_db),
    skip: int = 0,
    limit: int = 100,
) -> Any:
    """
    Retrieve shops.
    """
    shops = db.query(ShopModel).filter(ShopModel.is_approved == True).offset(skip).limit(limit).all()
    return shops

@router.post("/", response_model=Shop)
def create_shop(
    *,
    db: Session = Depends(deps.get_db),
    shop_in: ShopCreate,
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    """
    Create new shop.
    """
    shop = ShopModel(
        owner_id=current_user.id,
        **shop_in.dict()
    )
    db.add(shop)
    db.commit()
    db.refresh(shop)
    return shop

@router.get("/{shop_id}", response_model=Shop)
def read_shop(
    *,
    db: Session = Depends(deps.get_db),
    shop_id: int,
) -> Any:
    """
    Get shop by ID and track visit.
    """
    shop = db.query(ShopModel).filter(ShopModel.id == shop_id).first()
    if not shop:
        raise HTTPException(status_code=404, detail="Shop not found")
    
    # Analytics
    if shop.visit_count is None:
        shop.visit_count = 1
    else:
        shop.visit_count += 1
        
    db.commit()
    db.refresh(shop)
    return shop
