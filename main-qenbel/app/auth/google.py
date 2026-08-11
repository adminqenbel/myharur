from authlib.integrations.httpx_client import AsyncOAuth2Client
from app.config import get_settings

settings = get_settings()

GOOGLE_AUTH_URL = "https://accounts.google.com/o/oauth2/v2/auth"
GOOGLE_TOKEN_URL = "https://oauth2.googleapis.com/token"
GOOGLE_USERINFO_URL = "https://www.googleapis.com/oauth2/v3/userinfo"
SCOPES = "openid email profile"

class GoogleUser:
    def __init__(self, sub: str, email: str, name: str, picture: str):
        self.sub = sub
        self.email = email.lower().strip()
        self.name = name
        self.picture = picture

async def get_authorization_url(state: str, redis_client) -> str:
    """Store state in Redis with 10min TTL (CSRF protection)"""
    if redis_client:
        await redis_client.setex(f"oauth_state:{state}", 600, "1")
    
    client = AsyncOAuth2Client(
        client_id=settings.google_client_id,
        redirect_uri=settings.google_redirect_uri,
        scope=SCOPES
    )
    url, _ = client.create_authorization_url(
        GOOGLE_AUTH_URL,
        state=state,
        access_type="offline",
        prompt="select_account"
    )
    return url

async def exchange_code(code: str, state: str, redis_client) -> GoogleUser:
    """Verify state from Redis, exchange authorization code for Google user profile."""
    if redis_client:
        stored = await redis_client.get(f"oauth_state:{state}")
        if not stored:
            raise ValueError("Invalid or expired OAuth state")
        await redis_client.delete(f"oauth_state:{state}")
    
    async with AsyncOAuth2Client(
        client_id=settings.google_client_id,
        client_secret=settings.google_client_secret,
        redirect_uri=settings.google_redirect_uri
    ) as client:
        await client.fetch_token(
            GOOGLE_TOKEN_URL,
            code=code
        )
        resp = await client.get(GOOGLE_USERINFO_URL)
        resp.raise_for_status()
        info = resp.json()
    
    return GoogleUser(
        sub=info["sub"],
        email=info["email"],
        name=info.get("name", ""),
        picture=info.get("picture", "")
    )
