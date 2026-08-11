import httpx
from fastapi import APIRouter, Request, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from app.db.session import get_db
from app.config import get_settings

router = APIRouter(prefix="/api/v1/auth", tags=["Auth Provisioning"])
settings = get_settings()

@router.post("/provision")
async def provision_myharur_account(
    request: Request,
    db: AsyncSession = Depends(get_db)
):
    """
    Called by MyHarur client after receiving QenBel access token.
    Calls QenBel Identity Service to provision, then ensures local account.
    Client NEVER supplies mmid or qenbel_id in request body.
    """
    auth_header = request.headers.get("Authorization", "")
    if not auth_header.startswith("Bearer "):
        raise HTTPException(401, "Missing authorization token")
    
    async with httpx.AsyncClient() as client:
        try:
            resp = await client.post(
                f"{settings.qenbel_identity_url}/provision",
                json={"product_slug": "myharur"},
                headers={"Authorization": auth_header},
                timeout=10.0
            )
            if resp.status_code != 200:
                raise HTTPException(resp.status_code, f"Provisioning failed: {resp.text}")
            provision_data = resp.json()
        except httpx.RequestError as e:
            raise HTTPException(502, f"Identity service unavailable: {e}")
    
    mmid_str = provision_data["product_user_id"]
    qenbel_id = request.state.qenbel_id if hasattr(request.state, "qenbel_id") else None
    
    if not qenbel_id:
        raise HTTPException(401, "Could not resolve identity from token")
    
    await db.execute(
        text("""
            INSERT INTO myharur.accounts (mmid, qenbel_id)
            VALUES (:mmid, :qenbel_id)
            ON CONFLICT (qenbel_id) DO NOTHING
        """),
        {"mmid": mmid_str, "qenbel_id": qenbel_id}
    )
    await db.commit()
    
    result = await db.execute(
        text("SELECT mmid, onboarding_complete, status FROM myharur.accounts WHERE qenbel_id = :qid"),
        {"qid": qenbel_id}
    )
    account = result.mappings().one()
    
    return {
        "mmid": str(account["mmid"]),
        "onboarding_complete": account["onboarding_complete"],
        "status": account["status"]
    }
