from typing import Optional, List
from pydantic import BaseModel
from datetime import datetime

class JobListingBase(BaseModel):
    title: str
    company_name: Optional[str] = None
    job_type: str
    description: str
    salary_range: Optional[str] = None
    location: Optional[str] = None
    location_lat: Optional[float] = None
    location_lng: Optional[float] = None

class JobListingCreate(JobListingBase):
    pass

class JobListingUpdate(BaseModel):
    title: Optional[str] = None
    company_name: Optional[str] = None
    job_type: Optional[str] = None
    description: Optional[str] = None
    salary_range: Optional[str] = None
    status: Optional[str] = None

class JobListing(JobListingBase):
    id: int
    employer_id: int
    status: str
    is_employer_verified: bool
    created_at: datetime

    class Config:
        from_attributes = True
