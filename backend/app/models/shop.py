from sqlalchemy import Column, Integer, String, Boolean, Float, DateTime, ForeignKey, Text
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.session import Base

class ShopCategory(Base):
    __tablename__ = "shop_categories"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, index=True)
    icon = Column(String, nullable=True)

class Shop(Base):
    __tablename__ = "shops"
    id = Column(Integer, primary_key=True, index=True)
    owner_id = Column(Integer, ForeignKey("users.id"))
    category_id = Column(Integer, ForeignKey("shop_categories.id"))
    name = Column(String, index=True, nullable=False)
    description = Column(Text, nullable=True)
    logo_url = Column(String, nullable=True)
    cover_url = Column(String, nullable=True)
    location_lat = Column(Float, nullable=True)
    location_lng = Column(Float, nullable=True)
    address = Column(String, nullable=True)
    phone = Column(String, nullable=True)
    whatsapp = Column(String, nullable=True)
    opening_hours = Column(String, nullable=True)
    is_verified = Column(Boolean, default=False, index=True)
    is_approved = Column(Boolean, default=False, index=True)
    is_open = Column(Boolean, default=True)
    delivery_available = Column(Boolean, default=False)
    visit_count = Column(Integer, default=0)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    products = relationship("Product", back_populates="shop")
    offers = relationship("ShopOffer", back_populates="shop")
    images = relationship("ShopImage", back_populates="shop")

class Product(Base):
    __tablename__ = "products"
    id = Column(Integer, primary_key=True, index=True)
    shop_id = Column(Integer, ForeignKey("shops.id"))
    name = Column(String, index=True, nullable=False)
    description = Column(Text, nullable=True)
    price = Column(Float, nullable=False, index=True)
    bulk_price = Column(Float, nullable=True)
    stock = Column(Integer, default=0)
    image_url = Column(String, nullable=True)
    
    shop = relationship("Shop", back_populates="products")

class ShopOffer(Base):
    __tablename__ = "shop_offers"
    id = Column(Integer, primary_key=True, index=True)
    shop_id = Column(Integer, ForeignKey("shops.id"))
    title = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    discount_percentage = Column(Float, nullable=True)
    image_url = Column(String, nullable=True)
    valid_until = Column(DateTime(timezone=True), nullable=True)

    shop = relationship("Shop", back_populates="offers")

class ShopImage(Base):
    __tablename__ = "shop_images"
    id = Column(Integer, primary_key=True, index=True)
    shop_id = Column(Integer, ForeignKey("shops.id"))
    image_url = Column(String, nullable=False)

    shop = relationship("Shop", back_populates="images")
