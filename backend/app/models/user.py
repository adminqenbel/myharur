import uuid
from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, Date, Float, Text, Index, Table
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.session import Base


def generate_uid():
    return str(uuid.uuid4())


user_roles = Table(
    "user_roles",
    Base.metadata,
    Column("user_id", Integer, ForeignKey("users.id"), primary_key=True),
    Column("role_id", Integer, ForeignKey("roles.id"), primary_key=True),
)

class Role(Base):
    __tablename__ = "roles"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, index=True)  # Super Admin, Admin, Moderator, User, etc.


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
    
    # Primary role for backward compatibility
    role_id = Column(Integer, ForeignKey("roles.id"))
    
    last_login = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    role = relationship("Role", back_populates="primary_users", foreign_keys=[role_id])
    roles = relationship("Role", secondary=user_roles, backref="users")
    profile = relationship("Profile", back_populates="user", uselist=False)
    username_history = relationship("UsernameHistory", back_populates="user")


Role.primary_users = relationship("User", back_populates="role", foreign_keys=[User.role_id])

class UsernameHistory(Base):
    __tablename__ = "username_history"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    old_username = Column(String, nullable=True)
    new_username = Column(String, nullable=False)
    changed_at = Column(DateTime(timezone=True), server_default=func.now())
    
    user = relationship("User", back_populates="username_history")


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
    volunteer_hours = Column(Integer, default=0)
    emergency_score = Column(Integer, default=0)
    news_posted = Column(Integer, default=0)
    last_active_date = Column(Date, nullable=True)

    user = relationship("User", back_populates="profile")
