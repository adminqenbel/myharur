from typing import Optional, List
from pydantic import BaseModel, EmailStr, field_validator
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
    username: Optional[str] = None
    display_name: Optional[str] = None


class UserUpdate(UserBase):
    password: Optional[str] = None


class UsernameSet(BaseModel):
    username: str
    display_name: Optional[str] = None


class User(UserBase):
    id: int
    mid: Optional[str] = None
    username: Optional[str] = None
    display_name: Optional[str] = None
    username_required: bool = False
    role_id: Optional[int] = None
    is_setup_complete: bool = False
    is_banned: bool = False
    login_provider: Optional[str] = "email"
    created_at: datetime
    updated_at: Optional[datetime] = None
    last_login: Optional[datetime] = None
    profile: Optional[Profile] = None
    role: Optional[Role] = None
    roles: List[Role] = []

    class Config:
        from_attributes = True


class UserMe(User):
    """Public-facing user profile — UUID is never exposed."""


class Token(BaseModel):
    access_token: str
    refresh_token: Optional[str] = None
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
    uid: Optional[str] = None
    mid: Optional[str] = None
    username: Optional[str] = None
    display_name: Optional[str] = None
    email: str
    is_active: bool
    is_banned: bool = False
    login_provider: Optional[str] = None
    role: Optional[Role] = None
    roles: List[Role] = []
    profile: Optional[Profile] = None
    created_at: datetime
    last_login: Optional[datetime] = None
    username_required: bool = False

    class Config:
        from_attributes = True


class UsernameCheckResult(BaseModel):
    username: str
    available: bool
    error: Optional[str] = None


class UserSearchResult(BaseModel):
    id: int
    mid: Optional[str] = None
    username: Optional[str] = None
    display_name: Optional[str] = None
    avatar_url: Optional[str] = None
    role: Optional[Role] = None

    class Config:
        from_attributes = True
