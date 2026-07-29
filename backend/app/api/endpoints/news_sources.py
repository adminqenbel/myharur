from typing import List, Any
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.api import deps
from app.crud import crud_ingestion
from app.schemas import ingestion as schemas
from app.models.user import User

router = APIRouter()

@router.get("/", response_model=List[schemas.NewsSource])
def read_news_sources(
    db: Session = Depends(deps.get_db),
    skip: int = 0,
    limit: int = 100,
    current_user: User = Depends(deps.get_current_active_superuser),
) -> Any:
    """
    Retrieve news sources. (Admin only)
    """
    sources = crud_ingestion.get_news_sources(db, skip=skip, limit=limit)
    return sources

@router.post("/", response_model=schemas.NewsSource)
def create_news_source(
    *,
    db: Session = Depends(deps.get_db),
    source_in: schemas.NewsSourceCreate,
    current_user: User = Depends(deps.get_current_active_superuser),
) -> Any:
    """
    Create new news source. (Admin only)
    """
    source = crud_ingestion.create_news_source(db=db, source=source_in)
    return source

@router.put("/{source_id}", response_model=schemas.NewsSource)
def update_news_source(
    *,
    db: Session = Depends(deps.get_db),
    source_id: int,
    source_in: schemas.NewsSourceUpdate,
    current_user: User = Depends(deps.get_current_active_superuser),
) -> Any:
    """
    Update a news source. (Admin only)
    """
    source = crud_ingestion.update_news_source(db=db, source_id=source_id, source_update=source_in)
    if not source:
        raise HTTPException(status_code=404, detail="News source not found")
    return source

@router.delete("/{source_id}", response_model=dict)
def delete_news_source(
    *,
    db: Session = Depends(deps.get_db),
    source_id: int,
    current_user: User = Depends(deps.get_current_active_superuser),
) -> Any:
    """
    Delete a news source. (Admin only)
    """
    success = crud_ingestion.delete_news_source(db=db, source_id=source_id)
    if not success:
        raise HTTPException(status_code=404, detail="News source not found")
    return {"status": "success"}
