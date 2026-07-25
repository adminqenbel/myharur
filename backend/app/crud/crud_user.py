from typing import Optional
from sqlalchemy.orm import Session
from app.models.user import User, Role, Profile
from app.schemas.user import UserCreate, UserUpdate
from app.core.security import get_password_hash, verify_password

def get_user(db: Session, user_id: int) -> Optional[User]:
    return db.query(User).filter(User.id == user_id).first()

def get_user_by_email(db: Session, email: str) -> Optional[User]:
    return db.query(User).filter(User.email == email).first()

def get_role_by_name(db: Session, name: str) -> Optional[Role]:
    return db.query(Role).filter(Role.name == name).first()

def create_user(db: Session, user_in: UserCreate) -> User:
    role = get_role_by_name(db, user_in.role_name)
    if not role:
        # Create role if it doesn't exist (useful for first run)
        role = Role(name=user_in.role_name)
        db.add(role)
        db.commit()
        db.refresh(role)
        
    db_obj = User(
        email=user_in.email,
        hashed_password=get_password_hash(user_in.password),
        role_id=role.id,
        is_active=True
    )
    db.add(db_obj)
    db.commit()
    db.refresh(db_obj)
    
    # Create empty profile
    profile = Profile(user_id=db_obj.id)
    db.add(profile)
    db.commit()
    db.refresh(db_obj)
    
    return db_obj

def authenticate(db: Session, email: str, password: str) -> Optional[User]:
    user = get_user_by_email(db, email=email)
    if not user:
        return None
    if not verify_password(password, user.hashed_password):
        return None
    return user
