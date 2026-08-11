from pydantic_settings import BaseSettings, SettingsConfigDict
from functools import lru_cache
from typing import List

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    supabase_url: str = "https://krfzaemoendekexglkfj.supabase.co"
    supabase_service_role_key: str = "placeholder_key"
    google_client_id: str = "976428818123-abv9j8joclbmdr9i26vh0vgk0bj285js.apps.googleusercontent.com"
    google_client_secret: str = "placeholder_secret"
    google_redirect_uri: str = "http://localhost:8001/auth/callback"
    jwt_private_key_pem: str = "placeholder_rsa_private_key"
    jwt_public_key_pem: str = "placeholder_rsa_public_key"
    jwt_access_token_ttl_minutes: int = 15
    jwt_refresh_token_ttl_days: int = 30
    redis_url: str = "redis://localhost:6379/0"
    allowed_origins: str = "http://localhost:3000,http://localhost:8000"
    environment: str = "development"

    @property
    def allowed_origins_list(self) -> List[str]:
        return [o.strip() for o in self.allowed_origins.split(",") if o.strip()]

    @property
    def is_production(self) -> bool:
        return self.environment == "production"

@lru_cache
def get_settings() -> Settings:
    return Settings()
