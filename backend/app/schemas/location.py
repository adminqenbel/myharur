from typing import Optional, List
from pydantic import BaseModel

class LocationBase(BaseModel):
    name: str
    is_active: bool = True

class StateCreate(LocationBase):
    pass

class State(LocationBase):
    id: int

    class Config:
        orm_mode = True

class DistrictCreate(LocationBase):
    state_id: int

class District(LocationBase):
    id: int
    state_id: int

    class Config:
        orm_mode = True

class TalukCreate(LocationBase):
    district_id: int

class Taluk(LocationBase):
    id: int
    district_id: int

    class Config:
        orm_mode = True

class TownCreate(LocationBase):
    taluk_id: int
    pincode: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None

class Town(LocationBase):
    id: int
    taluk_id: int
    pincode: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None

    class Config:
        orm_mode = True

class VillageCreate(LocationBase):
    taluk_id: int
    panchayat: Optional[str] = None
    pincode: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None

class Village(LocationBase):
    id: int
    taluk_id: int
    panchayat: Optional[str] = None
    pincode: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None

    class Config:
        orm_mode = True
