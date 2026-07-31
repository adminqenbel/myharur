from typing import Optional, List
from pydantic import BaseModel
from datetime import datetime

class MarketplaceListingBase(BaseModel):
    type: str
    title: str
    description: Optional[str] = None
    price: Optional[float] = None
    status: Optional[str] = "active"

class MarketplaceListingCreate(MarketplaceListingBase):
    pass

class MarketplaceListingUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    price: Optional[float] = None
    status: Optional[str] = None

class MarketplaceListing(MarketplaceListingBase):
    id: int
    user_id: int
    created_at: datetime

    class Config:
        from_attributes = True
