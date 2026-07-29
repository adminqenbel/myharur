from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.api import deps
from app.crud import crud_location
from app.schemas import location as schemas

router = APIRouter()

@router.get("/states", response_model=List[schemas.State])
def read_states(skip: int = 0, limit: int = 100, db: Session = Depends(deps.get_db)):
    states = crud_location.get_states(db, skip=skip, limit=limit)
    return states

@router.post("/states", response_model=schemas.State)
def create_state(state: schemas.StateCreate, db: Session = Depends(deps.get_db)):
    return crud_location.create_state(db=db, state=state)

@router.get("/districts", response_model=List[schemas.District])
def read_districts(state_id: int, db: Session = Depends(deps.get_db)):
    districts = crud_location.get_districts_by_state(db, state_id=state_id)
    return districts

@router.post("/districts", response_model=schemas.District)
def create_district(district: schemas.DistrictCreate, db: Session = Depends(deps.get_db)):
    return crud_location.create_district(db=db, district=district)

@router.get("/taluks", response_model=List[schemas.Taluk])
def read_taluks(district_id: int, db: Session = Depends(deps.get_db)):
    taluks = crud_location.get_taluks_by_district(db, district_id=district_id)
    return taluks

@router.post("/taluks", response_model=schemas.Taluk)
def create_taluk(taluk: schemas.TalukCreate, db: Session = Depends(deps.get_db)):
    return crud_location.create_taluk(db=db, taluk=taluk)

@router.get("/towns", response_model=List[schemas.Town])
def read_towns(taluk_id: int, db: Session = Depends(deps.get_db)):
    towns = crud_location.get_towns_by_taluk(db, taluk_id=taluk_id)
    return towns

@router.post("/towns", response_model=schemas.Town)
def create_town(town: schemas.TownCreate, db: Session = Depends(deps.get_db)):
    return crud_location.create_town(db=db, town=town)

@router.get("/villages", response_model=List[schemas.Village])
def read_villages(taluk_id: int, db: Session = Depends(deps.get_db)):
    villages = crud_location.get_villages_by_taluk(db, taluk_id=taluk_id)
    return villages

@router.post("/villages", response_model=schemas.Village)
def create_village(village: schemas.VillageCreate, db: Session = Depends(deps.get_db)):
    return crud_location.create_village(db=db, village=village)
