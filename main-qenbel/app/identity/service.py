from uuid import UUID, uuid4
from datetime import datetime, timedelta, timezone
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, text
from app.db.models import Account, OAuthIdentity, Session, ProductMembership, ProductRegistry
from app.auth.jwt import create_refresh_token, sign_access_token
from app.auth.google import GoogleUser
from app.config import get_settings

settings = get_settings()

async def find_or_create_account(google_user: GoogleUser, db: AsyncSession) -> Account:
    """Atomic find-or-create account from Google user profile."""
    # Step 1: Look up by provider identity
    result = await db.execute(
        select(OAuthIdentity).where(
            OAuthIdentity.provider == "google",
            OAuthIdentity.provider_user_id == google_user.sub
        )
    )
    oauth_row = result.scalar_one_or_none()
    
    if oauth_row:
        account = await db.get(Account, oauth_row.qenbel_id)
        return account
    
    # Step 2: Look up by email
    result = await db.execute(
        select(Account).where(Account.email_normalized == google_user.email)
    )
    account = result.scalar_one_or_none()
    
    if not account:
        account = Account(
            email_normalized=google_user.email,
            display_name=google_user.name,
            avatar_url=google_user.picture
        )
        db.add(account)
        await db.flush()
    
    oauth = OAuthIdentity(
        qenbel_id=account.qenbel_id,
        provider="google",
        provider_user_id=google_user.sub,
        provider_email=google_user.email
    )
    db.add(oauth)
    await db.commit()
    await db.refresh(account)
    
    return account

async def create_session(qenbel_id: UUID, db: AsyncSession, user_agent: str = None, ip: str = None) -> tuple[str, str]:
    """Returns (access_token, raw_refresh_token)."""
    account = await db.get(Account, qenbel_id)
    
    raw_refresh, token_hash = create_refresh_token()
    expires_at = datetime.now(timezone.utc) + timedelta(days=settings.jwt_refresh_token_ttl_days)
    
    session = Session(
        qenbel_id=qenbel_id,
        refresh_token_hash=token_hash,
        expires_at=expires_at,
        user_agent=user_agent,
        ip_address=ip
    )
    db.add(session)
    await db.commit()
    
    access_token = sign_access_token(str(qenbel_id), account.email_normalized)
    return access_token, raw_refresh

async def provision_product(qenbel_id: UUID, product_slug: str, db: AsyncSession) -> dict:
    """Idempotent product provisioning."""
    result = await db.execute(
        select(ProductRegistry).where(
            ProductRegistry.product_slug == product_slug,
            ProductRegistry.is_active == True
        )
    )
    product = result.scalar_one_or_none()
    if not product:
        raise ValueError(f"Product '{product_slug}' not found or inactive")
    
    new_product_user_id = str(uuid4())
    await db.execute(
        text("""
            INSERT INTO qenbel_identity.product_memberships
              (qenbel_id, product_slug, product_user_id)
            VALUES
              (:qenbel_id, :product_slug, :product_user_id)
            ON CONFLICT (qenbel_id, product_slug) DO NOTHING
        """),
        {
            "qenbel_id": str(qenbel_id),
            "product_slug": product_slug,
            "product_user_id": new_product_user_id
        }
    )
    await db.commit()
    
    result = await db.execute(
        select(ProductMembership).where(
            ProductMembership.qenbel_id == qenbel_id,
            ProductMembership.product_slug == product_slug
        )
    )
    membership = result.scalar_one()
    return {
        "product_user_id": membership.product_user_id,
        "product_slug": product_slug,
        "provisioned_at": membership.provisioned_at.isoformat() if membership.provisioned_at else datetime.now(timezone.utc).isoformat()
    }
