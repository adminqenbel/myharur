from pydantic_settings import BaseSettings, SettingsConfigDict
from functools import lru_cache
from typing import List

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    supabase_url: str = "https://krfzaemoendekexglkfj.supabase.co"
    supabase_service_role_key: str = "placeholder_key"
    jwt_public_key_pem: str = "placeholder_rsa_public_key"
    qenbel_identity_url: str = "http://localhost:8001"
    redis_url: str = "redis://localhost:6379/0"
    gemini_api_key: str = "placeholder_gemini_key"
    gemini_daily_limit_per_user: int = 100
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
