import hashlib
import secrets
from datetime import datetime, timedelta, timezone
from jose import jwt, JWTError
from app.config import get_settings

settings = get_settings()

def sign_access_token(qenbel_id: str, email: str) -> str:
    """Sign RS256 access token. Only call this in main-qenbel service."""
    now = datetime.now(timezone.utc)
    payload = {
        "sub": str(qenbel_id),
        "email": email,
        "iat": now,
        "exp": now + timedelta(minutes=settings.jwt_access_token_ttl_minutes),
        "type": "access",
        "iss": "qenbel-identity"
    }
    priv_key = settings.jwt_private_key_pem.replace("\\n", "\n")
    return jwt.encode(
        payload,
        priv_key,
        algorithm="RS256"
    )

def verify_access_token(token: str) -> dict:
    """Verify RS256 token using public key. Safe to call in any service."""
    try:
        pub_key = settings.jwt_public_key_pem.replace("\\n", "\n")
        payload = jwt.decode(
            token,
            pub_key,
            algorithms=["RS256"],
            options={"verify_exp": True}
        )
        if payload.get("type") != "access":
            raise ValueError("Not an access token")
        if payload.get("iss") != "qenbel-identity":
            raise ValueError("Invalid issuer")
        return payload
    except JWTError as e:
        raise ValueError(f"Invalid token: {e}")

def create_refresh_token() -> tuple[str, str]:
    """Returns (raw_token, sha256_hash). Store hash only."""
    raw = secrets.token_urlsafe(64)
    token_hash = hashlib.sha256(raw.encode()).hexdigest()
    return raw, token_hash

def hash_refresh_token(raw_token: str) -> str:
    return hashlib.sha256(raw_token.encode()).hexdigest()
