from typing import Optional, List
from pydantic import BaseModel, EmailStr
from datetime import datetime

class ProfileBase(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    phone: Optional[str] = None
    bio: Optional[str] = None
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

    class Config:
        orm_mode = True

class Role(BaseModel):
    id: int
    name: str

    class Config:
        orm_mode = True

class UserBase(BaseModel):
    email: EmailStr
    is_active: Optional[bool] = True

class UserCreate(UserBase):
    password: str
    role_name: str = "User" # Default role is User

class UserUpdate(UserBase):
    password: Optional[str] = None

class User(UserBase):
    id: int
    role_id: Optional[int]
    created_at: datetime
    updated_at: Optional[datetime]
    profile: Optional[Profile] = None
    role: Optional[Role] = None

    class Config:
        orm_mode = True

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenPayload(BaseModel):
    sub: Optional[int] = None
