from typing import Any, List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, UploadFile, File
from sqlalchemy.orm import Session
from sqlalchemy import func
from pydantic import BaseModel
from datetime import datetime

from app.api import deps
from app.schemas.shop import Shop, ShopCreate, ShopUpdate
from app.models.shop import Shop as ShopModel, ShopCategory, Product, ShopOffer, ShopImage
from app.models.user import User as UserModel

router = APIRouter()


# ── Schemas ───────────────────────────────────────────────────────────────────

class CategoryOut(BaseModel):
    id: int
    name: str
    icon: Optional[str] = None
    class Config:
        from_attributes = True

class ProductCreate(BaseModel):
    name: str
    description: Optional[str] = None
    price: float
    bulk_price: Optional[float] = None
    stock: int = 0
    image_url: Optional[str] = None

class ProductOut(ProductCreate):
    id: int
    shop_id: int
    class Config:
        from_attributes = True

class OfferCreate(BaseModel):
    title: str
    description: Optional[str] = None
    discount_percentage: Optional[float] = None
    image_url: Optional[str] = None
    valid_until: Optional[datetime] = None

class OfferOut(OfferCreate):
    id: int
    shop_id: int
    class Config:
        from_attributes = True

class ShopFull(BaseModel):
    id: int
    owner_id: int
    name: str
    description: Optional[str] = None
    logo_url: Optional[str] = None
    cover_url: Optional[str] = None
    address: Optional[str] = None
    phone: Optional[str] = None
    whatsapp: Optional[str] = None
    opening_hours: Optional[str] = None
    location_lat: Optional[float] = None
    location_lng: Optional[float] = None
    is_open: bool = True
    is_verified: bool = False
    is_approved: bool = False
    delivery_available: bool = False
    visit_count: int = 0
    created_at: datetime
    category: Optional[CategoryOut] = None
    products: List[ProductOut] = []
    offers: List[OfferOut] = []
    images: List[str] = []
    owner_name: Optional[str] = None
    owner_phone: Optional[str] = None

    class Config:
        from_attributes = True


def _serialize_shop(shop: ShopModel, db: Session) -> dict:
    """Serialize a shop with nested relations and owner info."""
    from app.models.user import Profile as ProfileModel
    owner_profile = db.query(ProfileModel).filter(ProfileModel.user_id == shop.owner_id).first()
    owner_name = None
    owner_phone = None
    if owner_profile:
        owner_name = f"{owner_profile.first_name or ''} {owner_profile.last_name or ''}".strip() or None
        owner_phone = owner_profile.phone

    # Load category
    category = None
    if shop.category_id:
        cat = db.query(ShopCategory).filter(ShopCategory.id == shop.category_id).first()
        if cat:
            category = {"id": cat.id, "name": cat.name, "icon": cat.icon}

    return {
        "id": shop.id,
        "owner_id": shop.owner_id,
        "name": shop.name,
        "description": shop.description,
        "logo_url": shop.logo_url,
        "cover_url": shop.cover_url,
        "address": shop.address,
        "phone": shop.phone,
        "whatsapp": shop.whatsapp,
        "opening_hours": shop.opening_hours,
        "location_lat": shop.location_lat,
        "location_lng": shop.location_lng,
        "is_open": shop.is_open,
        "is_verified": shop.is_verified,
        "is_approved": shop.is_approved,
        "delivery_available": shop.delivery_available,
        "visit_count": shop.visit_count or 0,
        "created_at": shop.created_at.isoformat() if shop.created_at else None,
        "category": category,
        "products": [
            {
                "id": p.id,
                "shop_id": p.shop_id,
                "name": p.name,
                "description": p.description,
                "price": p.price,
                "bulk_price": p.bulk_price,
                "stock": p.stock,
                "image_url": p.image_url,
            }
            for p in (shop.products or [])
        ],
        "offers": [
            {
                "id": o.id,
                "shop_id": o.shop_id,
                "title": o.title,
                "description": o.description,
                "discount_percentage": o.discount_percentage,
                "image_url": o.image_url,
                "valid_until": o.valid_until.isoformat() if o.valid_until else None,
            }
            for o in (shop.offers or [])
        ],
        "images": [img.image_url for img in (shop.images or [])],
        "owner_name": owner_name,
        "owner_phone": owner_phone,
    }


# ── Categories ────────────────────────────────────────────────────────────────

@router.get("/categories", response_model=List[CategoryOut])
def list_categories(db: Session = Depends(deps.get_db)) -> Any:
    """Return all shop categories."""
    return db.query(ShopCategory).order_by(ShopCategory.name).all()


# ── Public Shop Listing ───────────────────────────────────────────────────────

@router.get("/")
def read_shops(
    db: Session = Depends(deps.get_db),
    category_id: Optional[int] = Query(None),
    sort: Optional[str] = Query("newest", description="newest | popular"),
    q: Optional[str] = Query(None, description="Search by name"),
    skip: int = 0,
    limit: int = 100,
) -> Any:
    """Retrieve approved shops for public listing."""
    query = db.query(ShopModel).filter(ShopModel.is_approved == True)

    if category_id:
        query = query.filter(ShopModel.category_id == category_id)

    if q:
        query = query.filter(ShopModel.name.ilike(f"%{q}%"))

    if sort == "popular":
        query = query.order_by(ShopModel.visit_count.desc())
    else:
        query = query.order_by(ShopModel.created_at.desc())

    shops = query.offset(skip).limit(limit).all()
    return [_serialize_shop(s, db) for s in shops]


# ── My Shops (owner) ──────────────────────────────────────────────────────────

@router.get("/my-shops")
def get_my_shops(
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    """Get all shops owned by the current user (any approval status)."""
    shops = db.query(ShopModel).filter(ShopModel.owner_id == current_user.id).order_by(ShopModel.created_at.desc()).all()
    return [_serialize_shop(s, db) for s in shops]


# ── Create Shop ───────────────────────────────────────────────────────────────

@router.post("/")
def create_shop(
    *,
    db: Session = Depends(deps.get_db),
    shop_in: ShopCreate,
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    """
    Register a new shop. Auto-approves for admins/shop-admins.
    Regular users get pending status (is_approved=False).
    """
    from app.core.rbac import get_user_permissions

    # Count existing shops
    existing_count = db.query(ShopModel).filter(ShopModel.owner_id == current_user.id).count()

    perms = get_user_permissions(db, current_user)
    user_roles = [r.name for r in current_user.roles]
    if current_user.role:
        user_roles.append(current_user.role.name)

    is_privileged = "Super Admin" in user_roles or "Admin" in user_roles or "Unlimited Shops" in perms

    if existing_count >= 2 and not is_privileged:
        raise HTTPException(
            status_code=403,
            detail="Maximum 2 shops allowed per user. Contact admin for more."
        )

    # Auto-approve for admins, shop-admins, and verified businesses
    auto_approve = is_privileged or "Shop Admin" in user_roles or "Verified Business" in user_roles

    # Validate category exists
    if shop_in.category_id:
        cat = db.query(ShopCategory).filter(ShopCategory.id == shop_in.category_id).first()
        if not cat:
            raise HTTPException(status_code=400, detail="Invalid category")

    shop = ShopModel(
        owner_id=current_user.id,
        is_approved=auto_approve,
        is_verified=False,
        **shop_in.model_dump()
    )
    db.add(shop)
    db.commit()
    db.refresh(shop)
    return {
        **_serialize_shop(shop, db),
        "message": "Shop registered successfully!" if auto_approve else "Shop submitted for approval. You will be notified once approved.",
        "auto_approved": auto_approve,
    }


# ── Get Single Shop ────────────────────────────────────────────────────────────

@router.get("/{shop_id}")
def read_shop(
    *,
    db: Session = Depends(deps.get_db),
    shop_id: int,
) -> Any:
    """Get a single shop by ID and track visit count."""
    shop = db.query(ShopModel).filter(ShopModel.id == shop_id).first()
    if not shop:
        raise HTTPException(status_code=404, detail="Shop not found")

    # Track visit
    shop.visit_count = (shop.visit_count or 0) + 1
    db.commit()
    db.refresh(shop)
    return _serialize_shop(shop, db)


# ── Update Shop ───────────────────────────────────────────────────────────────

@router.put("/{shop_id}")
def update_shop(
    shop_id: int,
    shop_in: ShopUpdate,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    """Update own shop details."""
    shop = db.query(ShopModel).filter(ShopModel.id == shop_id).first()
    if not shop:
        raise HTTPException(status_code=404, detail="Shop not found")

    user_roles = [r.name for r in current_user.roles]
    if current_user.role:
        user_roles.append(current_user.role.name)

    is_admin = "Super Admin" in user_roles or "Admin" in user_roles
    if shop.owner_id != current_user.id and not is_admin:
        raise HTTPException(status_code=403, detail="Not authorized to edit this shop")

    update_data = shop_in.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(shop, key, value)

    db.commit()
    db.refresh(shop)
    return _serialize_shop(shop, db)


# ── Toggle Open/Closed ────────────────────────────────────────────────────────

@router.put("/{shop_id}/toggle-open")
def toggle_shop_open(
    shop_id: int,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    """Toggle shop open/closed status."""
    shop = db.query(ShopModel).filter(ShopModel.id == shop_id).first()
    if not shop:
        raise HTTPException(status_code=404, detail="Shop not found")
    if shop.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized")

    shop.is_open = not shop.is_open
    db.commit()
    return {"is_open": shop.is_open, "message": "Shop is now OPEN" if shop.is_open else "Shop is now CLOSED"}


# ── Delete Shop ───────────────────────────────────────────────────────────────

@router.delete("/{shop_id}")
def delete_shop(
    shop_id: int,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    """Delete own shop."""
    shop = db.query(ShopModel).filter(ShopModel.id == shop_id).first()
    if not shop:
        raise HTTPException(status_code=404, detail="Shop not found")

    user_roles = [r.name for r in current_user.roles]
    if current_user.role:
        user_roles.append(current_user.role.name)

    is_admin = "Super Admin" in user_roles or "Admin" in user_roles
    if shop.owner_id != current_user.id and not is_admin:
        raise HTTPException(status_code=403, detail="Not authorized")

    db.delete(shop)
    db.commit()
    return {"message": "Shop deleted successfully"}


# ── Products ──────────────────────────────────────────────────────────────────

@router.post("/{shop_id}/products")
def add_product(
    shop_id: int,
    product_in: ProductCreate,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    """Add a product to a shop."""
    shop = db.query(ShopModel).filter(ShopModel.id == shop_id).first()
    if not shop:
        raise HTTPException(status_code=404, detail="Shop not found")
    if shop.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized")

    product = Product(shop_id=shop_id, **product_in.model_dump())
    db.add(product)
    db.commit()
    db.refresh(product)
    return {"id": product.id, "shop_id": product.shop_id, **product_in.model_dump()}


@router.delete("/{shop_id}/products/{product_id}")
def delete_product(
    shop_id: int,
    product_id: int,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    shop = db.query(ShopModel).filter(ShopModel.id == shop_id).first()
    if not shop or shop.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized")

    product = db.query(Product).filter(Product.id == product_id, Product.shop_id == shop_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")

    db.delete(product)
    db.commit()
    return {"message": "Product deleted"}


# ── Offers ────────────────────────────────────────────────────────────────────

@router.post("/{shop_id}/offers")
def add_offer(
    shop_id: int,
    offer_in: OfferCreate,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    """Add a special offer to a shop."""
    shop = db.query(ShopModel).filter(ShopModel.id == shop_id).first()
    if not shop:
        raise HTTPException(status_code=404, detail="Shop not found")
    if shop.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized")

    offer = ShopOffer(shop_id=shop_id, **offer_in.model_dump())
    db.add(offer)
    db.commit()
    db.refresh(offer)
    return {"id": offer.id, "shop_id": offer.shop_id, **offer_in.model_dump()}


@router.delete("/{shop_id}/offers/{offer_id}")
def delete_offer(
    shop_id: int,
    offer_id: int,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    shop = db.query(ShopModel).filter(ShopModel.id == shop_id).first()
    if not shop or shop.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized")

    offer = db.query(ShopOffer).filter(ShopOffer.id == offer_id, ShopOffer.shop_id == shop_id).first()
    if not offer:
        raise HTTPException(status_code=404, detail="Offer not found")

    db.delete(offer)
    db.commit()
    return {"message": "Offer deleted"}


# ── Admin Endpoints ───────────────────────────────────────────────────────────

@router.get("/admin/pending")
def list_pending_shops(
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    """[Admin] List all shops pending approval."""
    from app.core.rbac import get_user_permissions
    perms = get_user_permissions(db, current_user)
    user_roles = [r.name for r in current_user.roles]
    if current_user.role:
        user_roles.append(current_user.role.name)

    if "Read" not in perms and "Super Admin" not in user_roles and "Admin" not in user_roles:
        raise HTTPException(status_code=403, detail="Admin access required")

    shops = db.query(ShopModel).filter(ShopModel.is_approved == False).order_by(ShopModel.created_at.desc()).all()
    return [_serialize_shop(s, db) for s in shops]


@router.get("/admin/all")
def list_all_shops_admin(
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
    status: Optional[str] = Query(None, description="pending | approved | all"),
) -> Any:
    """[Admin] List all shops with filter by approval status."""
    from app.core.rbac import get_user_permissions
    perms = get_user_permissions(db, current_user)
    user_roles = [r.name for r in current_user.roles]
    if current_user.role:
        user_roles.append(current_user.role.name)
    if "Read" not in perms and "Super Admin" not in user_roles and "Admin" not in user_roles:
        raise HTTPException(status_code=403, detail="Admin access required")

    query = db.query(ShopModel)
    if status == "pending":
        query = query.filter(ShopModel.is_approved == False)
    elif status == "approved":
        query = query.filter(ShopModel.is_approved == True)

    shops = query.order_by(ShopModel.created_at.desc()).all()
    return [_serialize_shop(s, db) for s in shops]


@router.put("/admin/{shop_id}/approve")
def approve_shop(
    shop_id: int,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    """[Admin] Approve a shop."""
    from app.core.rbac import get_user_permissions
    perms = get_user_permissions(db, current_user)
    user_roles = [r.name for r in current_user.roles]
    if current_user.role:
        user_roles.append(current_user.role.name)
    if "Manage News" not in perms and "Super Admin" not in user_roles and "Admin" not in user_roles:
        raise HTTPException(status_code=403, detail="Admin access required")

    shop = db.query(ShopModel).filter(ShopModel.id == shop_id).first()
    if not shop:
        raise HTTPException(status_code=404, detail="Shop not found")

    shop.is_approved = True
    db.commit()

    # Create notification for shop owner
    try:
        from app.models.system import NotificationQueue
        notif = NotificationQueue(
            user_id=shop.owner_id,
            title="🎉 Shop Approved!",
            message=f"Your shop '{shop.name}' has been approved and is now live on MyHarur.",
            status="unread",
            priority="High"
        )
        db.add(notif)
        db.commit()
    except Exception:
        pass

    return {"message": f"Shop '{shop.name}' approved successfully", "shop_id": shop_id}


@router.put("/admin/{shop_id}/reject")
def reject_shop(
    shop_id: int,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    """[Admin] Reject and delete a pending shop."""
    from app.core.rbac import get_user_permissions
    perms = get_user_permissions(db, current_user)
    user_roles = [r.name for r in current_user.roles]
    if current_user.role:
        user_roles.append(current_user.role.name)
    if "Manage News" not in perms and "Super Admin" not in user_roles and "Admin" not in user_roles:
        raise HTTPException(status_code=403, detail="Admin access required")

    shop = db.query(ShopModel).filter(ShopModel.id == shop_id).first()
    if not shop:
        raise HTTPException(status_code=404, detail="Shop not found")

    shop_name = shop.name
    owner_id = shop.owner_id

    # Notify owner
    try:
        from app.models.system import NotificationQueue
        notif = NotificationQueue(
            user_id=owner_id,
            title="Shop Registration Rejected",
            message=f"Your shop '{shop_name}' could not be approved. Please contact admin for details.",
            status="unread",
            priority="normal"
        )
        db.add(notif)
    except Exception:
        pass

    db.delete(shop)
    db.commit()
    return {"message": f"Shop '{shop_name}' rejected and removed"}


@router.put("/admin/{shop_id}/verify")
def verify_shop(
    shop_id: int,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    """[Admin] Mark a shop as officially verified (blue tick)."""
    from app.core.rbac import get_user_permissions
    perms = get_user_permissions(db, current_user)
    user_roles = [r.name for r in current_user.roles]
    if current_user.role:
        user_roles.append(current_user.role.name)
    if "Super Admin" not in user_roles and "Admin" not in user_roles:
        raise HTTPException(status_code=403, detail="Only admins can verify shops")

    shop = db.query(ShopModel).filter(ShopModel.id == shop_id).first()
    if not shop:
        raise HTTPException(status_code=404, detail="Shop not found")

    shop.is_verified = True
    if not shop.is_approved:
        shop.is_approved = True
    db.commit()
    return {"message": f"Shop '{shop.name}' is now verified", "shop_id": shop_id}
