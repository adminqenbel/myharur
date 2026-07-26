from typing import Optional, List
from pydantic import BaseModel
from datetime import datetime

class ShopBase(BaseModel):
    name: str
    description: Optional[str] = None
    category_id: int
    address: Optional[str] = None
    phone: Optional[str] = None
    whatsapp: Optional[str] = None
    opening_hours: Optional[str] = None
    visit_count: int = 0
    location_lat: Optional[float] = None
    location_lng: Optional[float] = None

class ShopCreate(ShopBase):
    pass

class ShopUpdate(ShopBase):
    name: Optional[str] = None
    category_id: Optional[int] = None

class Shop(ShopBase):
    id: int
    owner_id: int
    logo_url: Optional[str] = None
    cover_url: Optional[str] = None
    is_verified: bool
    is_approved: bool
    created_at: datetime

    class Config:
        from_attributes = True
