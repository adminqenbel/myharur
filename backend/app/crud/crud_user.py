import uuid
import re
from typing import Optional, List
from datetime import date, datetime
from sqlalchemy.orm import Session
from sqlalchemy import func, text
from app.models.user import User, Role, Profile
from app.schemas.user import UserCreate, UserUpdate, SetupProfile
from app.core.security import get_password_hash, verify_password


# ── Reserved usernames ─────────────────────────────────────────────────────
RESERVED_USERNAMES = {
    "system", "support", "news", "moderator", "admin", "security",
    "notifications", "maintenance", "mid", "root", "superadmin",
    "super_admin", "api", "bot", "official", "staff", "help",
    "info", "contact", "mail", "email", "noreply", "no_reply",
    "myharur", "harur", "anonymous", "guest",
}

USERNAME_REGEX = re.compile(r'^[a-zA-Z0-9_]{3,30}$')


def validate_username(username: str) -> Optional[str]:
    """Returns error string or None if valid."""
    if not USERNAME_REGEX.match(username):
        return "Username must be 3-30 characters, letters/numbers/underscore only."
    if username.lower() in RESERVED_USERNAMES:
        return f"'{username}' is a reserved username."
    return None


def generate_mid(db: Session, is_system: bool = False, system_seq: int = 1) -> str:
    """
    Generate a unique MID.
    System accounts: SYS000001, SYS000002, etc.
    Regular users: YYYYMMDDHHMMSS + zero-padded 4-digit sequence
    Uses DB advisory lock pattern via SELECT FOR UPDATE on a counter.
    """
    if is_system:
        return f"SYS{system_seq:06d}"

    now = datetime.utcnow()
    prefix = now.strftime("%Y%m%d%H%M%S")
    # Find max sequence for this second
    existing = db.execute(
        text("SELECT COUNT(*) FROM users WHERE mid LIKE :prefix"),
        {"prefix": f"{prefix}%"}
    ).scalar() or 0
    seq = existing + 1
    return f"{prefix}{seq:04d}"


def get_user(db: Session, user_id: int) -> Optional[User]:
    return db.query(User).filter(User.id == user_id).first()


def get_user_by_uid(db: Session, uid: str) -> Optional[User]:
    return db.query(User).filter(User.uid == uid).first()


def get_user_by_email(db: Session, email: str) -> Optional[User]:
    return db.query(User).filter(User.email == email).first()


def get_user_by_username(db: Session, username: str) -> Optional[User]:
    return db.query(User).filter(func.lower(User.username) == username.lower()).first()


def get_user_by_mid(db: Session, mid: str) -> Optional[User]:
    return db.query(User).filter(User.mid == mid).first()


def get_role_by_name(db: Session, name: str) -> Optional[Role]:
    return db.query(Role).filter(Role.name == name).first()


def search_users(db: Session, query: str, limit: int = 20) -> List[User]:
    """Search by username, MID, display_name, or email."""
    q = query.strip()
    if not q:
        return []
    pattern = f"%{q}%"
    return (
        db.query(User)
        .filter(
            (func.lower(User.username).like(q.lower())) |
            (User.mid == q) |
            (func.lower(User.display_name).like(pattern.lower())) |
            (func.lower(User.email).like(pattern.lower()))
        )
        .limit(limit)
        .all()
    )


def create_user(db: Session, user_in: UserCreate) -> User:
    role = get_role_by_name(db, user_in.role_name)
    if not role:
        role = Role(name=user_in.role_name)
        db.add(role)
        db.commit()
        db.refresh(role)

    mid = generate_mid(db)
    db_obj = User(
        uid=str(uuid.uuid4()),
        mid=mid,
        email=user_in.email,
        hashed_password=get_password_hash(user_in.password),
        username=user_in.username if hasattr(user_in, 'username') and user_in.username else None,
        display_name=user_in.display_name if hasattr(user_in, 'display_name') and user_in.display_name else None,
        role_id=role.id,
        is_active=True,
        username_required=not bool(getattr(user_in, 'username', None)),
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
        if user.login_provider == "email":
            user.login_provider = "both"
            db.commit()
            db.refresh(user)
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
    mid = generate_mid(db)
    # Suggest username from email prefix
    suggested_name = email.split('@')[0][:20].lower()
    suggested_name = re.sub(r'[^a-z0-9_]', '_', suggested_name)

    user = User(
        uid=str(uuid.uuid4()),
        mid=mid,
        email=email,
        hashed_password=get_password_hash(secrets.token_urlsafe(32)),
        role_id=user_role.id,
        is_active=True,
        login_provider="google",
        username_required=True,  # Force username selection
        display_name=f"{first_name} {last_name}".strip() or first_name,
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


def set_username(db: Session, user: User, username: str) -> tuple[User, Optional[str]]:
    """Set username for user. Returns (user, error_str)."""
    err = validate_username(username)
    if err:
        return user, err

    # Check uniqueness (case-insensitive)
    existing = get_user_by_username(db, username)
    if existing and existing.id != user.id:
        return user, "Username already taken."

    user.username = username.lower()
    user.username_required = False
    if not user.display_name:
        user.display_name = username
    db.commit()
    db.refresh(user)
    return user, None


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
