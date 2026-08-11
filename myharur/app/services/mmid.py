from sqlalchemy import text
from app.db.session import AsyncSessionLocal

async def resolve_mmid(qenbel_id: str, redis_client=None) -> str:
    """Resolve qenbel_id to mmid with Redis caching."""
    if redis_client:
        try:
            cached = await redis_client.get(f"mmid:{qenbel_id}")
            if cached:
                return cached
        except Exception:
            pass
    
    async with AsyncSessionLocal() as db:
        result = await db.execute(
            text("SELECT mmid FROM myharur.accounts WHERE qenbel_id = :qid AND status = 'active'"),
            {"qid": qenbel_id}
        )
        row = result.fetchone()
        if not row:
            raise ValueError(f"Account for qenbel_id '{qenbel_id}' not found or inactive")
        
        mmid_str = str(row[0])
        
    if redis_client:
        try:
            await redis_client.setex(f"mmid:{qenbel_id}", 300, mmid_str)
        except Exception:
            pass
            
    return mmid_str
