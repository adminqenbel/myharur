import uuid
import re
from typing import Optional, List
from datetime import date, datetime
from sqlalchemy.orm import Session
from sqlalchemy import func, text
from app.models.user import User, Role, Profile, UsernameHistory
from app.schemas.user import UserCreate, UserUpdate, SetupProfile
from app.core.security import get_password_hash, verify_password


RESERVED_USERNAMES = {
    "system", "support", "news", "moderator", "admin", "security",
    "notifications", "maintenance", "mid", "root", "superadmin",
    "super_admin", "systemadmin", "system_admin", "sysadmin", "sys_admin",
    "api", "bot", "official", "staff", "help", "administrator",
    "info", "contact", "mail", "email", "noreply", "no_reply",
    "myharur", "harur", "anonymous", "guest", "null", "undefined",
    "owner", "webmaster", "police", "hospital", "collector", 
    "verification", "weather", "emergency", "developer", "municipality", 
    "government", "gov"
}

ABUSIVE_WORDS = {
    "fuck", "shit", "bitch", "asshole", "cunt", "dick", "pussy",
    "cock", "slut", "whore", "bastard", "nigger", "faggot",
    "porn", "sex", "rape", "murder", "kill", "nazi",
}

USERNAME_REGEX = re.compile(r'^[a-zA-Z0-9_\.]{3,30}$')


def validate_username(username: str) -> Optional[str]:
    """Returns error string or None if valid."""
    if not USERNAME_REGEX.match(username):
        return "Username must be 3-30 characters, letters/numbers/underscore only (no emojis, unicode, or spaces)."

    lower_uname = username.lower()
    
    # Fuzzy match reserved words
    for reserved in RESERVED_USERNAMES:
        if reserved in lower_uname:
            return f"Username contains reserved word '{reserved}'."

    for word in ABUSIVE_WORDS:
        if word in lower_uname:
            return "Username contains inappropriate language."

    return None


def validate_display_name(name: str) -> Optional[str]:
    """Returns error string or None if valid."""
    if not name or not name.strip():
        return "Display name cannot be empty."
    if len(name.strip()) > 60:
        return "Display name must be 60 characters or fewer."
    lower = name.lower()
    for word in ABUSIVE_WORDS:
        if word in lower:
            return "Display name contains inappropriate language."
    return None


def generate_mid(db: Session, is_system: bool = False, system_seq: int = 1) -> str:
    """
    Generate a unique MID.
    System accounts: SYS000001, SYS000002, etc.
    Regular users: YYYYMMDDHHMMSS + 4 random digits
    """
    if is_system:
        return f"SYS{system_seq:06d}"

    now = datetime.utcnow()
    prefix = now.strftime("%Y%m%d%H%M%S")
    import secrets
    import string
    random_digits = ''.join(secrets.choice(string.digits) for _ in range(4))
    return f"{prefix}{random_digits}"


def ensure_user_identifiers(db: Session, user: User) -> User:
    """Backfill uid/mid and flag username_required for legacy accounts."""
    changed = False
    if not user.uid:
        user.uid = str(uuid.uuid4())
        changed = True
    if not user.mid:
        user.mid = generate_mid(db)
        changed = True
    is_system = (user.mid or "").startswith("SYS") or (user.email or "").endswith("@myharur.local")
    if not user.username and not is_system and user.username_required is not True:
        user.username_required = True
        changed = True
    if changed:
        db.commit()
        db.refresh(user)
    return user


def is_username_available(db: Session, username: str, exclude_user_id: Optional[int] = None) -> tuple[bool, Optional[str]]:
    """Check username availability. Returns (available, error_message)."""
    err = validate_username(username)
    if err:
        return False, err
    existing = get_user_by_username(db, username)
    if existing and (exclude_user_id is None or existing.id != exclude_user_id):
        return False, "Username already taken."
    return True, None


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


def search_users(
    db: Session,
    query: str,
    limit: int = 20,
    *,
    include_email: bool = False,
    include_uid: bool = False,
) -> List[User]:
    """Search by username, MID, display_name; email/uid for admin/internal only."""
    q = query.strip()
    if not q:
        return []
    pattern = f"%{q}%"
    filters = (
        (func.lower(User.username).like(q.lower())) |
        (User.mid == q) |
        (User.mid.like(f"{q}%")) |
        (func.lower(User.display_name).like(pattern.lower()))
    )
    if include_email:
        filters = filters | (func.lower(User.email).like(pattern.lower()))
    if include_uid:
        filters = filters | (User.uid == q)
    return db.query(User).filter(filters).limit(limit).all()


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


def set_username(db: Session, user: User, username: str, display_name: Optional[str] = None, phone: Optional[str] = None) -> tuple[User, Optional[str]]:
    """Set username for user. Returns (user, error_str)."""
    ensure_user_identifiers(db, user)
    available, err = is_username_available(db, username, exclude_user_id=user.id)
    if not available:
        return user, err

    # Log into history if changing
    if user.username and user.username != username.lower():
        history_entry = UsernameHistory(
            user_id=user.id,
            old_username=user.username,
            new_username=username.lower()
        )
        db.add(history_entry)

    user.username = username.lower()
    user.username_required = False
    if display_name:
        dn_err = validate_display_name(display_name)
        if dn_err:
            return user, dn_err
        user.display_name = display_name.strip()[:60]
    elif not user.display_name:
        user.display_name = username
        
    if phone:
        if not user.profile:
            profile = Profile(user_id=user.id)
            db.add(profile)
            user.profile = profile
        user.profile.phone = phone
        
    db.commit()
    db.refresh(user)
    return user, None


def complete_setup(db: Session, user: User, setup_in: SetupProfile) -> User:
    for word in ABUSIVE_WORDS:
        if setup_in.first_name and word in setup_in.first_name.lower():
            raise ValueError("First name contains inappropriate language.")
        if setup_in.last_name and word in setup_in.last_name.lower():
            raise ValueError("Last name contains inappropriate language.")

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
    from datetime import datetime, timedelta, timezone

    user = get_user_by_email(db, email=email)
    if not user:
        user = get_user_by_username(db, username=email)
    if not user:
        return None

    # Check if account is locked
    if user.locked_until and user.locked_until > datetime.now(timezone.utc):
        raise ValueError(f"Account locked due to multiple failed login attempts. Try again later.")

    if not verify_password(password, user.hashed_password):
        # Increment failed attempts
        user.failed_login_attempts = (user.failed_login_attempts or 0) + 1
        if user.failed_login_attempts >= 5:
            user.locked_until = datetime.now(timezone.utc) + timedelta(minutes=15)
        db.commit()
        return None

    # Successful login, reset failed attempts
    if user.failed_login_attempts > 0 or user.locked_until:
        user.failed_login_attempts = 0
        user.locked_until = None
        db.commit()
        
    return user


def update_password(db: Session, user: User, new_password: str) -> User:
    user.hashed_password = get_password_hash(new_password)
    if user.login_provider == "google":
        user.login_provider = "both"
    db.commit()
    db.refresh(user)
    return user
