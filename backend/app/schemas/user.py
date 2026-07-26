from typing import Optional, List
from pydantic import BaseModel, EmailStr
from datetime import datetime


class ProfileBase(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    phone: Optional[str] = None
    bio: Optional[str] = None
    address: Optional[str] = None
    ward: Optional[str] = None
    city: Optional[str] = "Harur"
    state: Optional[str] = "Tamil Nadu"
    pincode: Optional[str] = None
    location_lat: Optional[float] = None
    location_lng: Optional[float] = None
    town: str = "MyHarur"
    avatar_url: Optional[str] = None
    cover_url: Optional[str] = None

class ProfileCreate(ProfileBase):
    pass

class ProfileUpdate(ProfileBase):
    pass

class Profile(ProfileBase):
    id: int
    user_id: int
    streak_days: int = 0
    reward_points: int = 0

    class Config:
        from_attributes = True


class SetupProfile(BaseModel):
    first_name: str
    last_name: Optional[str] = None
    phone: str
    address: Optional[str] = None
    ward: Optional[str] = None
    location_lat: Optional[float] = None
    location_lng: Optional[float] = None


class Role(BaseModel):
    id: int
    name: str

    class Config:
        from_attributes = True


class UserBase(BaseModel):
    email: EmailStr
    is_active: Optional[bool] = True


class UserCreate(UserBase):
    password: str
    role_name: str = "User"


class UserUpdate(UserBase):
    password: Optional[str] = None


class User(UserBase):
    id: int
    uid: Optional[str] = None
    role_id: Optional[int]
    is_setup_complete: bool = False
    login_provider: Optional[str] = "email"
    created_at: datetime
    updated_at: Optional[datetime]
    profile: Optional[Profile] = None
    role: Optional[Role] = None

    class Config:
        from_attributes = True


class Token(BaseModel):
    access_token: str
    token_type: str
    user: Optional[User] = None


class TokenPayload(BaseModel):
    sub: Optional[int] = None


class PasswordChange(BaseModel):
    old_password: str
    new_password: str


class PasswordSet(BaseModel):
    new_password: str


class AdminUserList(BaseModel):
    id: int
    uid: Optional[str]
    email: str
    is_active: bool
    login_provider: Optional[str]
    role: Optional[Role] = None
    profile: Optional[Profile] = None
    created_at: datetime

    class Config:
        from_attributes = True
