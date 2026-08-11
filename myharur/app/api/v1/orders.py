from fastapi import APIRouter, Request, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from app.db.session import get_db
from app.db.idor import set_rls_context

router = APIRouter(prefix="/api/v1/orders", tags=["Orders"])

@router.get("/mine")
async def get_my_orders(request: Request, db: AsyncSession = Depends(get_db)):
    mmid = request.state.mmid
    await set_rls_context(db, mmid)
    
    result = await db.execute(
        text("SELECT * FROM myharur.orders WHERE mmid = :mmid ORDER BY created_at DESC LIMIT 50"),
        {"mmid": mmid}
    )
    return [dict(row) for row in result.mappings().all()]

@router.get("/{order_id}")
async def get_order(order_id: str, request: Request, db: AsyncSession = Depends(get_db)):
    mmid = request.state.mmid
    await set_rls_context(db, mmid)
    
    result = await db.execute(
        text("SELECT * FROM myharur.orders WHERE id = :id"),
        {"id": order_id}
    )
    row = result.mappings().one_or_none()
    if not row:
        raise HTTPException(404, "Order not found")
    
    if str(row.get("mmid", "")) != str(mmid):
        raise HTTPException(403, "Access denied")
    
    return dict(row)
