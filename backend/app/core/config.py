import os
from typing import Optional
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    PROJECT_NAME: str = "MyHarur"
    API_V1_STR: str = "/api/v1"
    SECRET_KEY: str = "YOUR_SUPER_SECRET_KEY_FOR_JWT_HERE"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days
    ENV: str = "production"

    POSTGRES_SERVER: str = "localhost"
    POSTGRES_USER: str = "postgres"
    POSTGRES_PASSWORD: str = "postgres"
    POSTGRES_DB: str = "harur_town"
    POSTGRES_PORT: str = "5432"
    DATABASE_URL: Optional[str] = None

    @property
    def SQLALCHEMY_DATABASE_URI(self) -> str:
        if self.DATABASE_URL:
            if "db.krfzaemoendekexglkfj.supabase.co" in self.DATABASE_URL:
                uri = self.DATABASE_URL.replace(
                    "db.krfzaemoendekexglkfj.supabase.co:5432",
                    "aws-0-ap-northeast-1.pooler.supabase.com:6543"
                ).replace("postgres:", "postgres.krfzaemoendekexglkfj:")
                if "?" not in uri:
                    uri += "?sslmode=require"
                return uri
            return self.DATABASE_URL
        from urllib.parse import quote_plus, unquote_plus
        
        # Override legacy IPv6-only Supabase URL with the IPv4 Pooler URL
        # This fixes the socket.gaierror on servers like Hostinger that don't support IPv6
        server = self.POSTGRES_SERVER
        user = self.POSTGRES_USER
        port = self.POSTGRES_PORT
        
        if "db.krfzaemoendekexglkfj.supabase.co" in server:
            server = "aws-0-ap-northeast-1.pooler.supabase.com"
            user = "postgres.krfzaemoendekexglkfj"
            port = "6543"
            
        safe_password = quote_plus(unquote_plus(self.POSTGRES_PASSWORD))
        uri = f"postgresql://{user}:{safe_password}@{server}:{port}/{self.POSTGRES_DB}"
        if "supabase" in server or "pooler" in server:
            uri += "?sslmode=require"
        return uri

    class Config:
        env_file = ".env"
        extra = "ignore"

settings = Settings()

if settings.ENV == "production" and settings.SECRET_KEY == "YOUR_SUPER_SECRET_KEY_FOR_JWT_HERE":
    env_secret = os.getenv("SECRET_KEY")
    if env_secret:
        settings.SECRET_KEY = env_secret
