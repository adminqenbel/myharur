from typing import Any, List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.api import deps
from app.schemas.shop import Shop, ShopCreate
from app.models.shop import Shop as ShopModel
from app.models.user import User as UserModel

router = APIRouter()

@router.get("/", response_model=List[Shop])
def read_shops(
    db: Session = Depends(deps.get_db),
    category_id: Optional[int] = Query(None),
    sort: Optional[str] = Query("newest", description="newest, popular"),
    skip: int = 0,
    limit: int = 100,
) -> Any:
    """
    Retrieve shops.
    """
    q = db.query(ShopModel).filter(ShopModel.is_approved == True)
    if category_id:
        q = q.filter(ShopModel.category_id == category_id)
        
    if sort == "popular":
        q = q.order_by(ShopModel.visit_count.desc())
    else:
        q = q.order_by(ShopModel.created_at.desc())
        
    shops = q.offset(skip).limit(limit).all()
    return shops

@router.post("/", response_model=Shop)
def create_shop(
    *,
    db: Session = Depends(deps.get_db),
    shop_in: ShopCreate,
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    """
    Create new shop. Max 2 shops unless approved.
    """
    existing_shops = db.query(ShopModel).filter(ShopModel.owner_id == current_user.id).count()
    if existing_shops >= 2:
        # Require 'Unlimited Shops' permission or Super Admin
        from app.core.rbac import get_user_permissions
        perms = get_user_permissions(db, current_user)
        if "Unlimited Shops" not in perms and "Super Admin" not in [r.name for r in current_user.roles]:
            raise HTTPException(status_code=403, detail="Maximum 2 shops allowed. Additional shops require admin approval.")

    shop = ShopModel(
        owner_id=current_user.id,
        **shop_in.model_dump()
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
