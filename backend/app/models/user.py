import uuid
from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, Date, Float, Text, Index
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.session import Base


def generate_uid():
    return str(uuid.uuid4())


class Role(Base):
    __tablename__ = "roles"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, index=True)  # Super Admin, Admin, Moderator, User
    users = relationship("User", back_populates="role")


class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    uid = Column(String, unique=True, index=True, default=generate_uid)          # UUID — internal
    mid = Column(String, unique=True, index=True, nullable=True)                  # MID — human-readable permanent ID
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)

    # Identity
    username = Column(String, unique=True, index=True, nullable=True)             # Globally unique, case-insensitive stored lowercase
    display_name = Column(String, nullable=True)                                  # Editable, max 60 chars, Unicode
    username_required = Column(Boolean, default=False)                            # True → force username screen on next login

    is_active = Column(Boolean, default=True)
    is_banned = Column(Boolean, default=False)
    ban_reason = Column(String, nullable=True)
    is_setup_complete = Column(Boolean, default=False)
    login_provider = Column(String, default="email")  # "email", "google", "both"
    role_id = Column(Integer, ForeignKey("roles.id"))
    last_login = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    role = relationship("Role", back_populates="users")
    profile = relationship("Profile", back_populates="user", uselist=False)


class Profile(Base):
    __tablename__ = "profiles"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True)
    first_name = Column(String, nullable=True)
    last_name = Column(String, nullable=True)
    phone = Column(String, nullable=True)
    bio = Column(Text, nullable=True)
    address = Column(String, nullable=True)
    ward = Column(String, nullable=True)
    city = Column(String, default="Harur")
    state = Column(String, default="Tamil Nadu")
    pincode = Column(String, nullable=True)
    location_lat = Column(Float, nullable=True)
    location_lng = Column(Float, nullable=True)
    town = Column(String, default="MyHarur")
    avatar_url = Column(String, nullable=True)
    cover_url = Column(String, nullable=True)
    streak_days = Column(Integer, default=0)
    reward_points = Column(Integer, default=0)
    last_active_date = Column(Date, nullable=True)

    user = relationship("User", back_populates="profile")
