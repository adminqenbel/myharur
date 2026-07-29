from sqlalchemy.orm import Session
from app.models.location import State, District, Taluk, Town, Village
from app.schemas.location import StateCreate, DistrictCreate, TalukCreate, TownCreate, VillageCreate

def get_states(db: Session, skip: int = 0, limit: int = 100):
    return db.query(State).filter(State.is_active == True).offset(skip).limit(limit).all()

def create_state(db: Session, state: StateCreate):
    db_state = State(**state.dict())
    db.add(db_state)
    db.commit()
    db.refresh(db_state)
    return db_state

def get_districts_by_state(db: Session, state_id: int):
    return db.query(District).filter(District.state_id == state_id, District.is_active == True).all()

def create_district(db: Session, district: DistrictCreate):
    db_district = District(**district.dict())
    db.add(db_district)
    db.commit()
    db.refresh(db_district)
    return db_district

def get_taluks_by_district(db: Session, district_id: int):
    return db.query(Taluk).filter(Taluk.district_id == district_id, Taluk.is_active == True).all()

def create_taluk(db: Session, taluk: TalukCreate):
    db_taluk = Taluk(**taluk.dict())
    db.add(db_taluk)
    db.commit()
    db.refresh(db_taluk)
    return db_taluk

def get_towns_by_taluk(db: Session, taluk_id: int):
    return db.query(Town).filter(Town.taluk_id == taluk_id, Town.is_active == True).all()

def create_town(db: Session, town: TownCreate):
    db_town = Town(**town.dict())
    db.add(db_town)
    db.commit()
    db.refresh(db_town)
    return db_town

def get_villages_by_taluk(db: Session, taluk_id: int):
    return db.query(Village).filter(Village.taluk_id == taluk_id, Village.is_active == True).all()

def create_village(db: Session, village: VillageCreate):
    db_village = Village(**village.dict())
    db.add(db_village)
    db.commit()
    db.refresh(db_village)
    return db_village
