from pydantic import BaseModel, EmailStr
from typing import Optional

class GoogleAuthResponse(BaseModel):
    authorization_url: str
    state: str

class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "Bearer"
    expires_in: int = 900
    qenbel_id: str

class AccountInfo(BaseModel):
    qenbel_id: str
    email: EmailStr
    display_name: Optional[str] = None
    avatar_url: Optional[str] = None
    status: str

class ProvisionRequest(BaseModel):
    product_slug: str

class ProvisionResponse(BaseModel):
    product_user_id: str
    product_slug: str
    provisioned_at: str
