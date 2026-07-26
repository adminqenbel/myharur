import uuid
from typing import Optional
from datetime import date
from sqlalchemy.orm import Session
from app.models.user import User, Role, Profile
from app.schemas.user import UserCreate, UserUpdate, SetupProfile
from app.core.security import get_password_hash, verify_password


def get_user(db: Session, user_id: int) -> Optional[User]:
    return db.query(User).filter(User.id == user_id).first()


def get_user_by_uid(db: Session, uid: str) -> Optional[User]:
    return db.query(User).filter(User.uid == uid).first()


def get_user_by_email(db: Session, email: str) -> Optional[User]:
    return db.query(User).filter(User.email == email).first()


def get_role_by_name(db: Session, name: str) -> Optional[Role]:
    return db.query(Role).filter(Role.name == name).first()


def create_user(db: Session, user_in: UserCreate) -> User:
    role = get_role_by_name(db, user_in.role_name)
    if not role:
        role = Role(name=user_in.role_name)
        db.add(role)
        db.commit()
        db.refresh(role)

    db_obj = User(
        uid=str(uuid.uuid4()),
        email=user_in.email,
        hashed_password=get_password_hash(user_in.password),
        role_id=role.id,
        is_active=True,
        login_provider="email",
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


def create_or_link_google_user(db: Session, email: str, first_name: str, last_name: str, photo_url: str) -> User:
    """Find existing user by email and link Google, or create a fresh Google user."""
    user = get_user_by_email(db, email)

    if user:
        # Already exists — just mark as having google provider
        if user.login_provider == "email":
            user.login_provider = "both"
            db.commit()
            db.refresh(user)
        # Update avatar if not set
        if user.profile and not user.profile.avatar_url and photo_url:
            user.profile.avatar_url = photo_url
            db.commit()
        return user

    # New user via Google
    user_role = get_role_by_name(db, "User")
    if not user_role:
        user_role = Role(name="User")
        db.add(user_role)
        db.commit()
        db.refresh(user_role)

    import secrets
    user = User(
        uid=str(uuid.uuid4()),
        email=email,
        hashed_password=get_password_hash(secrets.token_urlsafe(32)),
        role_id=user_role.id,
        is_active=True,
        login_provider="google",
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    profile = Profile(
        user_id=user.id,
        first_name=first_name,
        last_name=last_name,
        avatar_url=photo_url
    )
    db.add(profile)
    db.commit()
    return user


def complete_setup(db: Session, user: User, setup_in: SetupProfile) -> User:
    profile = user.profile
    if not profile:
        profile = Profile(user_id=user.id)
        db.add(profile)

    profile.first_name = setup_in.first_name
    profile.last_name = setup_in.last_name
    profile.phone = setup_in.phone
    profile.address = setup_in.address
    profile.ward = setup_in.ward
    profile.location_lat = setup_in.location_lat
    profile.location_lng = setup_in.location_lng

    user.is_setup_complete = True
    db.commit()
    db.refresh(user)
    return user


def update_streak(db: Session, user: User) -> User:
    """Call on each login/open. Updates streak and last_active_date."""
    from datetime import date, timedelta
    profile = user.profile
    if not profile:
        return user

    today = date.today()
    if profile.last_active_date == today:
        return user  # Already active today

    if profile.last_active_date == today - timedelta(days=1):
        profile.streak_days = (profile.streak_days or 0) + 1
    else:
        profile.streak_days = 1  # Streak broken

    profile.last_active_date = today
    profile.reward_points = (profile.reward_points or 0) + 5  # 5 pts per active day
    db.commit()
    db.refresh(user)
    return user


def authenticate(db: Session, email: str, password: str) -> Optional[User]:
    user = get_user_by_email(db, email=email)
    if not user:
        return None
    if not verify_password(password, user.hashed_password):
        return None
    return user


def update_password(db: Session, user: User, new_password: str) -> User:
    user.hashed_password = get_password_hash(new_password)
    if user.login_provider == "google":
        user.login_provider = "both"
    db.commit()
    db.refresh(user)
    return user
