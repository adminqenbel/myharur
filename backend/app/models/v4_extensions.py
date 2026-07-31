from sqlalchemy import Column, Integer, String, Boolean, Float, DateTime, ForeignKey, Text, JSON, Table
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.session import Base

# ==========================================
# PHASE 2: NEW V4 EXTENSION TABLES
# ==========================================

# 1. PERMISSIONS
class Permission(Base):
    __tablename__ = "permissions"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, index=True)
    description = Column(String, nullable=True)

role_permissions = Table(
    "role_permissions",
    Base.metadata,
    Column("role_id", Integer, ForeignKey("roles.id"), primary_key=True),
    Column("permission_id", Integer, ForeignKey("permissions.id"), primary_key=True),
)

# 2. GOVERNMENT OFFICIALS
class GovernmentOfficial(Base):
    __tablename__ = "government_officials"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True)
    department = Column(String, index=True, nullable=False)
    designation = Column(String, nullable=False)
    office_address = Column(Text, nullable=True)
    office_phone = Column(String, nullable=True)
    is_verified = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

# 3. VOLUNTEERS
class Volunteer(Base):
    __tablename__ = "volunteers"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True)
    skills = Column(String, nullable=True)
    availability = Column(String, nullable=True)
    total_hours_logged = Column(Float, default=0.0)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

# 4. ORDERS (Marketplace / Shops)
class Order(Base):
    __tablename__ = "orders"
    id = Column(Integer, primary_key=True, index=True)
    buyer_id = Column(Integer, ForeignKey("users.id"))
    shop_id = Column(Integer, ForeignKey("shops.id"), nullable=True)
    total_amount = Column(Float, nullable=False)
    status = Column(String, default="Pending", index=True) # Pending, Accepted, Delivered, Cancelled
    shipping_address = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), index=True)
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

# 5. TOURNAMENTS
class Tournament(Base):
    __tablename__ = "tournaments"
    id = Column(Integer, primary_key=True, index=True)
    organizer_id = Column(Integer, ForeignKey("users.id"))
    sport_type = Column(String, index=True, nullable=False) # Cricket, Kabaddi, etc.
    name = Column(String, nullable=False)
    start_date = Column(DateTime(timezone=True))
    end_date = Column(DateTime(timezone=True))
    location = Column(String, nullable=True)
    prize_pool = Column(String, nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

# 6. LEADERBOARD (Snapshot cache table for optimization)
class LeaderboardSnapshot(Base):
    __tablename__ = "leaderboard_snapshots"
    id = Column(Integer, primary_key=True, index=True)
    category = Column(String, index=True, nullable=False) # e.g. "Volunteer", "Reputation"
    user_id = Column(Integer, ForeignKey("users.id"))
    rank = Column(Integer, nullable=False)
    score = Column(Float, nullable=False)
    snapshot_date = Column(DateTime(timezone=True), server_default=func.now(), index=True)

# 7. WEATHER
class Weather(Base):
    __tablename__ = "weather_logs"
    id = Column(Integer, primary_key=True, index=True)
    temperature = Column(Float, nullable=False)
    condition = Column(String, nullable=False)
    humidity = Column(Float, nullable=True)
    recorded_at = Column(DateTime(timezone=True), server_default=func.now(), index=True)

# 8. DONATION
class Donation(Base):
    __tablename__ = "donations"
    id = Column(Integer, primary_key=True, index=True)
    donor_id = Column(Integer, ForeignKey("users.id"), nullable=True) # Null if anonymous
    cause = Column(String, nullable=False)
    amount = Column(Float, nullable=False)
    transaction_id = Column(String, nullable=True)
    status = Column(String, default="Completed")
    created_at = Column(DateTime(timezone=True), server_default=func.now())

# 9. RESTAURANT RANKING
class RestaurantRanking(Base):
    __tablename__ = "restaurant_rankings"
    id = Column(Integer, primary_key=True, index=True)
    shop_id = Column(Integer, ForeignKey("shops.id"), unique=True)
    average_rating = Column(Float, default=0.0)
    total_reviews = Column(Integer, default=0)
    rank_score = Column(Float, default=0.0, index=True)
    last_updated = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
