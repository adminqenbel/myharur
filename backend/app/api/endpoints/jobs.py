from typing import Any, List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.api import deps
from app.models.jobs import JobListing as JobListingModel
from app.models.user import User as UserModel
from app.schemas.jobs import JobListingCreate, JobListingUpdate, JobListing

router = APIRouter()

@router.get("/", response_model=List[JobListing])
def get_jobs(
    db: Session = Depends(deps.get_db),
    type: Optional[str] = Query(None, description="Full-time, Part-time, Temporary, Volunteer, Internship"),
    location: Optional[str] = Query(None),
    sort: Optional[str] = Query("newest", description="newest, popular"),
    skip: int = 0, limit: int = 50,
) -> Any:
    q = db.query(JobListingModel).filter(JobListingModel.status == "active")
    if type:
        q = q.filter(JobListingModel.job_type == type)
    if location:
        q = q.filter(JobListingModel.location.ilike(f"%{location}%"))
        
    # Assuming we might add views count later for popularity, for now just sort by newest
    return q.order_by(JobListingModel.created_at.desc()).offset(skip).limit(limit).all()

@router.post("/", response_model=JobListing)
def create_job(
    job_in: JobListingCreate,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    from app.core.rbac import get_user_permissions
    perms = get_user_permissions(db, current_user)
    is_verified = "Verified Employer" in perms

    job = JobListingModel(
        employer_id=current_user.id,
        is_employer_verified=is_verified,
        **job_in.model_dump()
    )
    db.add(job)
    db.commit()
    db.refresh(job)
    return job
