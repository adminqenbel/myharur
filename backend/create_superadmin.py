import os
import sys

from sqlalchemy.orm import Session
from app.db.session import SessionLocal
from app.models.user import User, Role, Profile
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def get_password_hash(password):
    return pwd_context.hash(password)

def init_db():
    db: Session = SessionLocal()
    
    # 1. Create Super Admin Role
    super_admin_role = db.query(Role).filter(Role.name == "Super Admin").first()
    if not super_admin_role:
        super_admin_role = Role(name="Super Admin")
        db.add(super_admin_role)
        db.commit()
        db.refresh(super_admin_role)
        
    # 2. Create Super Admin User
    admin_email = "admin.qenbel@gmail.com"
    existing_user = db.query(User).filter(User.email == admin_email).first()
    if not existing_user:
        hashed_pw = get_password_hash("qenbel@admin")
        new_user = User(
            email=admin_email,
            hashed_password=hashed_pw,
            role_id=super_admin_role.id,
            is_active=True
        )
        db.add(new_user)
        db.commit()
        db.refresh(new_user)
        
        # 3. Create Profile
        new_profile = Profile(
            user_id=new_user.id,
            first_name="Qenbel",
            last_name="Admin",
            bio="Harur Town Super Administrator"
        )
        db.add(new_profile)
        db.commit()
        print(f"Super admin {admin_email} created successfully.")
    else:
        print(f"Super admin {admin_email} already exists.")
        
    db.close()

if __name__ == "__main__":
    init_db()
