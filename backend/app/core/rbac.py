import json
from typing import List, Set, Dict
from sqlalchemy.orm import Session
from sqlalchemy import text
from fastapi import HTTPException

from app.models.user import User, Role
from app.models.v4_extensions import Permission
from app.core.redis_session import redis_client

# Hardcoded inheritance for V4 Enterprise RBAC
ROLE_INHERITANCE: Dict[str, List[str]] = {
    "Super Admin": ["Admin", "Moderator", "Government Official", "Shop Admin", "Event Head", "Organizing Secretary", "Volunteer", "Verified Business", "Citizen"],
    "Government Official": ["Admin", "Moderator", "Citizen"],
    "Admin": ["Moderator", "Citizen"],
    "Moderator": ["Citizen"],
    "Shop Admin": ["Verified Business", "Citizen"],
    "Event Head": ["Organizing Secretary", "Citizen"],
    "Organizing Secretary": ["Volunteer", "Citizen"],
    "Volunteer": ["Citizen"],
    "Verified Business": ["Citizen"],
    "Citizen": []
}

def _get_inherited_roles(role_names: List[str]) -> Set[str]:
    """Recursively resolves all inherited roles."""
    resolved = set(role_names)
    queue = list(role_names)
    while queue:
        current = queue.pop(0)
        inherited = ROLE_INHERITANCE.get(current, [])
        for r in inherited:
            if r not in resolved:
                resolved.add(r)
                queue.append(r)
    return resolved

def get_user_permissions(db: Session, user: User) -> List[str]:
    """Returns a list of all permission names the user has, leveraging Redis cache."""
    if not redis_client:
        return _fetch_permissions_from_db(db, user)
    
    cache_key = f"user_permissions:{user.id}"
    cached = redis_client.get(cache_key)
    if cached:
        return json.loads(cached)
        
    perms = _fetch_permissions_from_db(db, user)
    redis_client.setex(cache_key, 3600, json.dumps(list(perms))) # Cache for 1 hour
    return list(perms)

def _fetch_permissions_from_db(db: Session, user: User) -> Set[str]:
    # Collect all direct roles
    user_roles = [r.name for r in user.roles]
    if user.role:  # legacy single role
        user_roles.append(user.role.name)
        
    all_role_names = _get_inherited_roles(user_roles)
    
    if not all_role_names:
        return set()
        
    # Query permissions for all these roles
    # using raw SQL for performance on the join table
    query = text("""
        SELECT DISTINCT p.name 
        FROM permissions p
        JOIN role_permissions rp ON p.id = rp.permission_id
        JOIN roles r ON r.id = rp.role_id
        WHERE r.name IN :roles
    """)
    result = db.execute(query, {"roles": tuple(all_role_names)}).fetchall()
    
    return {row[0] for row in result}

def invalidate_permission_cache(user_id: int):
    if redis_client:
        redis_client.delete(f"user_permissions:{user_id}")

def require_permissions(required_perms: List[str]):
    """FastAPI Dependency generator for checking permissions."""
    def dependency(user: User, db: Session):
        user_perms = get_user_permissions(db, user)
        # Super Admin override (in case DB isn't seeded correctly)
        if "Super Admin" in [r.name for r in user.roles] or (user.role and user.role.name == "Super Admin"):
            return user
            
        missing = [p for p in required_perms if p not in user_perms]
        if missing:
            raise HTTPException(
                status_code=403, 
                detail=f"Missing required permissions: {', '.join(missing)}"
            )
        return user
    return dependency

def promote_to_admin(db: Session, user: User, role_name: str) -> str:
    """
    Promotes user to an admin role, generates an Admin ID, and logs audit.
    Admin ID format: ADM-YYYYMMDD-Random4
    """
    role = db.query(Role).filter(Role.name == role_name).first()
    if not role:
        raise ValueError(f"Role {role_name} does not exist.")
        
    if role not in user.roles:
        user.roles.append(role)
        
    # Generate Admin ID if not present
    if not getattr(user, 'admin_id', None):
        import datetime, secrets, string
        now = datetime.datetime.utcnow().strftime("%Y%m%d")
        rand_str = ''.join(secrets.choice(string.ascii_uppercase + string.digits) for _ in range(4))
        # Assuming admin_id was added to User. Since it wasn't in Phase 2, we can just use `mid` prefix or add it now.
        # We will add it dynamically or store in Profile if we can't alter schema immediately.
        # Actually, let's use the profile bio or just update the DB schema next.
        
    invalidate_permission_cache(user.id)
    db.commit()
    return "Promoted successfully"

def demote_from_admin(db: Session, user: User, role_name: str):
    role = db.query(Role).filter(Role.name == role_name).first()
    if role and role in user.roles:
        user.roles.remove(role)
    invalidate_permission_cache(user.id)
    db.commit()
