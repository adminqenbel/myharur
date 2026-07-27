import uvicorn
import asyncio
import re
import threading
import time
import urllib.request
import os
from datetime import datetime

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import JSONResponse
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
import json
import logging
from app.core.config import settings
from app.api.api import api_router

# Setup structured JSON logger
logger = logging.getLogger("api_logger")
logger.setLevel(logging.INFO)
handler = logging.StreamHandler()
handler.setFormatter(logging.Formatter('%(message)s'))
if not logger.handlers:
    logger.addHandler(handler)

app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json"
)

# ── Middlewares & Rate Limiting ──────────────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.add_middleware(GZipMiddleware, minimum_size=1000)

limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

@app.middleware("http")
async def json_logging_middleware(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    
    log_dict = {
        "timestamp": datetime.utcnow().isoformat(),
        "method": request.method,
        "url": str(request.url.path),
        "status_code": response.status_code,
        "process_time_ms": round(process_time * 1000, 2),
        "client": request.client.host if request.client else None
    }
    logger.info(json.dumps(log_dict))
    return response

# ── Socket.IO Setup ──────────────────────────────────────────────────────────
import socketio
from jose import jwt, JWTError

sio_mgr = None
redis_url = os.getenv("REDIS_URL")
if redis_url:
    sio_mgr = socketio.AsyncRedisManager(redis_url)
    print(f"[Socket.IO] Using Redis Adapter: {redis_url}")
else:
    print("[Socket.IO] Using Local Adapter (No REDIS_URL)")

sio = socketio.AsyncServer(async_mode='asgi', cors_allowed_origins='*', client_manager=sio_mgr)

# User session cache: sid -> {user_id, username, display_name, role, avatar}
_socket_sessions = {}

# Typing state: room_id -> {user_id: timestamp}
_typing_state = {}


@sio.event
async def connect(sid, environ, auth):
    """Authenticate WebSocket connection via JWT. Cache user info to avoid DB hits."""
    token = None
    if auth and isinstance(auth, dict):
        token = auth.get('token')
    if not token:
        from urllib.parse import parse_qs
        qs = environ.get('QUERY_STRING', '')
        params = parse_qs(qs)
        if 'token' in params:
            token = params['token'][0]
    if not token:
        return False

    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id = int(payload.get('sub', 0))
        if not user_id:
            return False

        # Cache user info at connection time (auth once, use many)
        from app.db.session import SessionLocal
        from app.models.user import User as UserModel, Profile as ProfileModel
        db = SessionLocal()
        try:
            user = db.query(UserModel).filter(UserModel.id == user_id).first()
            if not user or not user.is_active or user.is_banned:
                return False
            profile = db.query(ProfileModel).filter(ProfileModel.user_id == user_id).first()
            display = user.display_name or user.username or "Anonymous"
            if profile and (profile.first_name or profile.last_name):
                display = f"{profile.first_name or ''} {profile.last_name or ''}".strip() or display
            _socket_sessions[sid] = {
                'user_id': user_id,
                'username': user.username or "",
                'display_name': display,
                'role': user.role.name if user.role else "User",
                'avatar': profile.avatar_url if profile else None,
                'mid': user.mid or "",
                'rooms': set(),
            }
        finally:
            db.close()

        # Auto-join user's personal room (for DMs / notifications)
        await sio.enter_room(sid, f'user_{user_id}')
        # Broadcast presence
        await sio.emit('presence', {'user_id': user_id, 'status': 'online'})
        print(f"[Socket.IO] User {user_id} connected (sid={sid})")
        return True
    except (JWTError, Exception) as e:
        print(f"[Socket.IO] Auth failed: {e}")
        return False


@sio.event
async def join_room(sid, data):
    """Join a chat room."""
    room_id = data.get('room_id') if isinstance(data, dict) else data
    room_name = f'chat_room_{room_id}'
    await sio.enter_room(sid, room_name)
    if sid in _socket_sessions:
        _socket_sessions[sid]['rooms'].add(room_name)
    print(f"[Socket.IO] sid={sid} joined {room_name}")


@sio.event
async def leave_room(sid, data):
    """Leave a chat room."""
    room_id = data.get('room_id') if isinstance(data, dict) else data
    room_name = f'chat_room_{room_id}'
    await sio.leave_room(sid, room_name)
    if sid in _socket_sessions:
        _socket_sessions[sid]['rooms'].discard(room_name)


@sio.event
async def typing(sid, data):
    """Broadcast typing indicator to the room (no DB involvement)."""
    session = _socket_sessions.get(sid)
    if not session:
        return
    room_id = data.get('room_id') if isinstance(data, dict) else None
    if not room_id:
        return
    is_typing = data.get('is_typing', True)
    await sio.emit('typing', {
        'user_id': session['user_id'],
        'username': session['username'],
        'display_name': session['display_name'],
        'is_typing': is_typing,
        'room_id': room_id,
    }, room=f'chat_room_{room_id}', skip_sid=sid)


@sio.event
async def send_message(sid, data):
    """
    OPTIMIZED FLOW:
    1. Build message data from CACHED session (no DB query)
    2. Emit to room IMMEDIATELY (~10ms)
    3. Save to DB in background (non-blocking)
    Target: < 100ms delivery
    """
    session = _socket_sessions.get(sid)
    if not session:
        return

    user_id = session['user_id']
    room_id = data.get('room_id')
    content = data.get('content', '').strip()
    client_msg_id = data.get('client_msg_id')  # Client's temp ID for dedup

    if not room_id or not content:
        return

    # Rate limiting: max 2 messages per second
    now_ts = time.time()
    last_msg_key = f'last_msg_{sid}'
    if _socket_sessions[sid].get('last_msg_time', 0) > now_ts - 0.5:
        return
    _socket_sessions[sid]['last_msg_time'] = now_ts

    # Process @mentions in content
    mentions = re.findall(r'@(\w+)', content)

    # Build message payload from CACHED session (no DB lookup)
    temp_id = f"temp_{sid}_{int(now_ts * 1000)}"
    msg_data = {
        'id': temp_id,
        'room_id': room_id,
        'sender_id': user_id,
        'username': session['username'],
        'display_name': session['display_name'],
        'sender_name': session['display_name'],
        'sender_role': session['role'],
        'sender_avatar': session['avatar'],
        'content': content,
        'mentions': mentions,
        'created_at': datetime.utcnow().isoformat(),
        'client_msg_id': client_msg_id,
    }

    # ── EMIT FIRST — before any DB work ──
    await sio.emit('new_message', msg_data, room=f'chat_room_{room_id}')

    # ── Notify mentioned users in their personal rooms ──
    if mentions:
        asyncio.create_task(_notify_mentions(mentions, msg_data))

    # ── Save to DB asynchronously (background task) ──
    asyncio.create_task(_save_message_to_db(user_id, room_id, content, temp_id))


async def _notify_mentions(mentions: list, msg_data: dict):
    """Notify @mentioned users in their personal room."""
    from app.db.session import SessionLocal
    from app.models.user import User as UserModel
    db = SessionLocal()
    try:
        for username in mentions:
            if username.lower() == "support":
                asyncio.create_task(_auto_reply_support(msg_data['room_id'], msg_data))
                continue
                
            user = db.query(UserModel).filter(UserModel.username == username.lower()).first()
            if user:
                await sio.emit('mention', msg_data, room=f'user_{user.id}')
    except Exception as e:
        print(f"[Socket.IO] Mention notify error: {e}")
    finally:
        db.close()

async def _auto_reply_support(room_id: int, original_msg_data: dict):
    """Keyword matching auto-reply bot for @support mentions."""
    await asyncio.sleep(1.5)  # Simulate typing delay
    from app.db.session import SessionLocal
    from app.models.user import User as UserModel
    from app.models.community import ChatMessage
    db = SessionLocal()
    try:
        support_user = db.query(UserModel).filter(UserModel.username == "support").first()
        if not support_user:
            return
            
        content = original_msg_data.get('content', '').lower()
        reply_text = "I'm the MyHarur support bot. I've noted your message and a human moderator will assist you shortly."
        
        if any(w in content for w in ["password", "login", "account", "locked"]):
            reply_text = "Having trouble with your account? An admin can reset your password or update your details. We've notified them."
        elif any(w in content for w in ["bug", "error", "issue", "crash", "not working"]):
            reply_text = "Thank you for reporting this issue! I've flagged it for our development team to investigate."
        elif any(w in content for w in ["hello", "hi", "help"]):
            reply_text = "Hello! I am the automated support assistant. Please describe your issue in detail and an admin will get back to you."

        msg = ChatMessage(room_id=room_id, sender_id=support_user.id, content=reply_text)
        db.add(msg)
        db.commit()
        db.refresh(msg)
        
        reply_data = {
            'id': msg.id,
            'room_id': room_id,
            'sender_id': support_user.id,
            'username': "support",
            'display_name': "MyHarur Support",
            'sender_name': "MyHarur Support",
            'sender_role': "Moderator",
            'sender_avatar': None,
            'content': reply_text,
            'mentions': [original_msg_data.get('username')],
            'created_at': datetime.utcnow().isoformat(),
            'client_msg_id': f"sys_{msg.id}",
        }
        await sio.emit('new_message', reply_data, room=f'chat_room_{room_id}')
    except Exception as e:
        print(f"[Socket.IO] Autobot error: {e}")
    finally:
        db.close()


async def _save_message_to_db(user_id: int, room_id: int, content: str, temp_id: str):
    """Background task: persist message and emit real ID back."""
    from app.db.session import SessionLocal
    from app.models.community import ChatMessage
    db = SessionLocal()
    try:
        msg = ChatMessage(room_id=room_id, sender_id=user_id, content=content)
        db.add(msg)
        db.commit()
        db.refresh(msg)
        # Emit real ID so clients can replace temp ID
        await sio.emit('message_confirmed', {
            'temp_id': temp_id,
            'real_id': msg.id,
            'room_id': room_id,
        }, room=f'chat_room_{room_id}')
    except Exception as e:
        print(f"[Socket.IO] DB save error: {e}")
        await sio.emit('message_failed', {'temp_id': temp_id}, room=f'user_{user_id}')
    finally:
        db.close()


@sio.event
async def disconnect(sid):
    """Clean up on disconnect."""
    session = _socket_sessions.pop(sid, None)
    if session:
        await sio.emit('presence', {'user_id': session['user_id'], 'status': 'offline'})
        print(f"[Socket.IO] User {session['user_id']} disconnected (sid={sid})")


# ── Wrap FastAPI with Socket.IO ASGI app ─────────────────────────────────────
socket_app = socketio.ASGIApp(sio, app)


# ── Gold/Rates Scraping ──────────────────────────────────────────────────────
from app.api.endpoints.rates import current_rates

def scrape_rates():
    try:
        url = "https://www.goodreturns.in/gold-rates/dharmapuri.html"
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        html = urllib.request.urlopen(req, timeout=10).read().decode('utf-8')
        matches = re.findall(r'₹\s*([0-9,]+)', html)
        prev_22k = current_rates.get("gold_22k_raw", 0)
        prev_24k = current_rates.get("gold_24k_raw", 0)
        if len(matches) >= 2:
            raw_22k = int(matches[0].replace(',', ''))
            raw_24k = int(matches[1].replace(',', ''))
            trend_22k = "↑" if raw_22k > prev_22k else ("↓" if raw_22k < prev_22k else "→")
            trend_24k = "↑" if raw_24k > prev_24k else ("↓" if raw_24k < prev_24k else "→")
            current_rates["gold_22k"] = f"₹{matches[0]}/g"
            current_rates["gold_24k"] = f"₹{matches[1]}/g"
            current_rates["gold_22k_raw"] = raw_22k
            current_rates["gold_24k_raw"] = raw_24k
            current_rates["gold_22k_prev"] = f"₹{prev_22k:,}/g" if prev_22k else current_rates["gold_22k"]
            current_rates["gold_24k_prev"] = f"₹{prev_24k:,}/g" if prev_24k else current_rates["gold_24k"]
            current_rates["gold_22k_trend"] = trend_22k
            current_rates["gold_24k_trend"] = trend_24k
        current_rates["silver"] = "₹102/g"
        current_rates["updated_at"] = datetime.utcnow().isoformat()
        print(f"[Rates] Scraped: 22K={current_rates['gold_22k']}, 24K={current_rates['gold_24k']}")
    except Exception as e:
        print(f"[Rates] Scrape error: {e}")
        if not current_rates.get("updated_at"):
            current_rates["updated_at"] = None


def keep_alive_loop():
    scrape_rates()
    loops = 0
    while True:
        try:
            time.sleep(600)  # 10 min
            loops += 1
            if loops % 12 == 0:  # Every 2 hours
                scrape_rates()
            # Keep-alive ping
            req = urllib.request.Request('https://myharur.onrender.com/health', headers={'User-Agent': 'KeepAlive'})
            with urllib.request.urlopen(req, timeout=10):
                pass
        except Exception:
            pass


# ── Startup ──────────────────────────────────────────────────────────────────
@app.on_event("startup")
async def startup_event():
    from app.db.session import engine, SessionLocal
    import app.models
    from app.db.session import Base
    from sqlalchemy import text

    # Create tables
    Base.metadata.create_all(bind=engine)

    # Run migrations
    with engine.begin() as conn:
        migrations = [
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS uid VARCHAR DEFAULT gen_random_uuid();",
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS mid VARCHAR UNIQUE;",
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS username VARCHAR UNIQUE;",
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS display_name VARCHAR;",
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS username_required BOOLEAN DEFAULT FALSE;",
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS is_banned BOOLEAN DEFAULT FALSE;",
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS ban_reason VARCHAR;",
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS last_login TIMESTAMPTZ;",
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS is_setup_complete BOOLEAN DEFAULT FALSE;",
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS login_provider VARCHAR DEFAULT 'email';",
            "ALTER TABLE profiles ADD COLUMN IF NOT EXISTS first_name VARCHAR;",
            "ALTER TABLE profiles ADD COLUMN IF NOT EXISTS last_name VARCHAR;",
            "ALTER TABLE profiles ADD COLUMN IF NOT EXISTS phone VARCHAR;",
            "ALTER TABLE profiles ADD COLUMN IF NOT EXISTS bio VARCHAR;",
            "ALTER TABLE profiles ADD COLUMN IF NOT EXISTS address VARCHAR;",
            "ALTER TABLE profiles ADD COLUMN IF NOT EXISTS ward VARCHAR;",
            "ALTER TABLE profiles ADD COLUMN IF NOT EXISTS city VARCHAR DEFAULT 'Harur';",
            "ALTER TABLE profiles ADD COLUMN IF NOT EXISTS state VARCHAR DEFAULT 'Tamil Nadu';",
            "ALTER TABLE profiles ADD COLUMN IF NOT EXISTS pincode VARCHAR;",
            "ALTER TABLE profiles ADD COLUMN IF NOT EXISTS location_lat FLOAT;",
            "ALTER TABLE profiles ADD COLUMN IF NOT EXISTS location_lng FLOAT;",
            "ALTER TABLE profiles ADD COLUMN IF NOT EXISTS town VARCHAR DEFAULT 'MyHarur';",
            "ALTER TABLE profiles ADD COLUMN IF NOT EXISTS avatar_url VARCHAR;",
            "ALTER TABLE profiles ADD COLUMN IF NOT EXISTS cover_url VARCHAR;",
            "ALTER TABLE profiles ADD COLUMN IF NOT EXISTS streak_days INTEGER DEFAULT 0;",
            "ALTER TABLE profiles ADD COLUMN IF NOT EXISTS reward_points INTEGER DEFAULT 0;",
            "ALTER TABLE profiles ADD COLUMN IF NOT EXISTS last_active_date DATE;",
            "ALTER TABLE news ADD COLUMN IF NOT EXISTS image_url VARCHAR;",
            "ALTER TABLE news ADD COLUMN IF NOT EXISTS content TEXT;",
            "ALTER TABLE news ADD COLUMN IF NOT EXISTS verified_by INTEGER;",
            "ALTER TABLE news ADD COLUMN IF NOT EXISTS verified_at TIMESTAMPTZ;",
            "ALTER TABLE news ALTER COLUMN category_id DROP NOT NULL;",
            "ALTER TABLE listings ADD COLUMN IF NOT EXISTS image_urls JSONB DEFAULT '[]';",
            "ALTER TABLE chat_messages ADD COLUMN IF NOT EXISTS mentions JSONB DEFAULT '[]';",
            # Index for case-insensitive username lookup
            "CREATE INDEX IF NOT EXISTS idx_users_username_lower ON users (LOWER(username));",
            "CREATE INDEX IF NOT EXISTS idx_users_mid ON users (mid);",
        ]
        for query in migrations:
            try:
                conn.execute(text(query))
            except Exception:
                pass

    # Migrate existing users: generate MID for those who don't have one
    db = SessionLocal()
    try:
        from app.models.user import User as UserModel, Role as RoleModel, Profile as ProfileModel
        from app.crud.crud_user import generate_mid

        users_no_mid = db.query(UserModel).filter(UserModel.mid == None).all()
        for u in users_no_mid:
            if not u.mid:
                u.mid = generate_mid(db)
                if not u.username:
                    u.username_required = True
        if users_no_mid:
            db.commit()
            print(f"[Migration] Generated MIDs for {len(users_no_mid)} existing users")

        # ── Seed Super Admin ──
        super_admin_email = "admin.qenbel@gmail.com"
        from app.core.security import get_password_hash

        sa_role = db.query(RoleModel).filter(RoleModel.name == "Super Admin").first()
        if not sa_role:
            sa_role = RoleModel(name="Super Admin")
            db.add(sa_role)
            db.commit()

        user_role = db.query(RoleModel).filter(RoleModel.name == "User").first()
        if not user_role:
            user_role = RoleModel(name="User")
            db.add(user_role)
            db.commit()

        mod_role = db.query(RoleModel).filter(RoleModel.name == "Moderator").first()
        if not mod_role:
            mod_role = RoleModel(name="Moderator")
            db.add(mod_role)
            db.commit()

        admin_role = db.query(RoleModel).filter(RoleModel.name == "Admin").first()
        if not admin_role:
            admin_role = RoleModel(name="Admin")
            db.add(admin_role)
            db.commit()

        super_admin = db.query(UserModel).filter(UserModel.email == super_admin_email).first()
        if not super_admin:
            import uuid as _uuid
            super_admin = UserModel(
                uid=str(_uuid.uuid4()),
                mid="SYS000001",
                email=super_admin_email,
                username="superadmin",
                display_name="Super Admin",
                hashed_password=get_password_hash("qenbel@admin"),
                role_id=sa_role.id,
                is_active=True,
                username_required=False,
                login_provider="email",
            )
            db.add(super_admin)
            db.commit()
            db.refresh(super_admin)
            if not db.query(ProfileModel).filter(ProfileModel.user_id == super_admin.id).first():
                db.add(ProfileModel(user_id=super_admin.id, first_name="Super", last_name="Admin"))
                db.commit()
        else:
            super_admin.hashed_password = get_password_hash("qenbel@admin")
            super_admin.role_id = sa_role.id
            if not super_admin.mid:
                super_admin.mid = "SYS000001"
            if not super_admin.username:
                super_admin.username = "superadmin"
                super_admin.username_required = False
            if super_admin.login_provider == "google":
                super_admin.login_provider = "both"
            db.commit()

        # ── Seed System Account (@system) for automated posts ──
        system_email = "system@myharur.local"
        system_user = db.query(UserModel).filter(UserModel.email == system_email).first()
        if not system_user:
            import uuid as _uuid, secrets
            system_user = UserModel(
                uid=str(_uuid.uuid4()),
                mid="SYS000002",
                email=system_email,
                username="system",
                display_name="MyHarur System",
                hashed_password=get_password_hash(secrets.token_urlsafe(32)),
                role_id=sa_role.id,
                is_active=True,
                username_required=False,
                login_provider="email",
            )
            db.add(system_user)
            db.commit()
            db.refresh(system_user)
            if not db.query(ProfileModel).filter(ProfileModel.user_id == system_user.id).first():
                db.add(ProfileModel(user_id=system_user.id, first_name="MyHarur", last_name="System"))
                db.commit()
            print("[Seed] Created @system account")

        # ── Seed @news account ──
        news_email = "news@myharur.local"
        news_user = db.query(UserModel).filter(UserModel.email == news_email).first()
        if not news_user:
            import uuid as _uuid, secrets
            news_user = UserModel(
                uid=str(_uuid.uuid4()),
                mid="SYS000003",
                email=news_email,
                username="news",
                display_name="MyHarur News",
                hashed_password=get_password_hash(secrets.token_urlsafe(32)),
                role_id=sa_role.id,
                is_active=True,
                username_required=False,
                login_provider="email",
            )
            db.add(news_user)
            db.commit()
            print("[Seed] Created @news account")

        # ── Seed @support account ──
        support_email = "support@myharur.local"
        support_user = db.query(UserModel).filter(UserModel.email == support_email).first()
        if not support_user:
            import uuid as _uuid, secrets
            support_user = UserModel(
                uid=str(_uuid.uuid4()),
                mid="SYS000004",
                email=support_email,
                username="support",
                display_name="MyHarur Support",
                hashed_password=get_password_hash(secrets.token_urlsafe(32)),
                role_id=mod_role.id,
                is_active=True,
                username_required=False,
                login_provider="email",
            )
            db.add(support_user)
            db.commit()
            print("[Seed] Created @support account")

        # ── Auto-disable maintenance mode on startup ──
        from app.models.system import SystemSetting
        setting = db.query(SystemSetting).filter(SystemSetting.key == "maintenance_mode").first()
        if not setting:
            setting = SystemSetting(key="maintenance_mode", value="false")
            db.add(setting)
        else:
            setting.value = "false"
        db.commit()
        print("[System] Maintenance mode automatically disabled on startup")

    finally:
        db.close()

    os.makedirs("static/uploads", exist_ok=True)
    threading.Thread(target=keep_alive_loop, daemon=True).start()


app.include_router(api_router, prefix=settings.API_V1_STR)


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    import traceback
    import os
    is_dev = os.getenv("ENV", "production") == "development"
    content = {"message": "Internal Server Error", "detail": str(exc)}
    if is_dev:
        content["traceback"] = traceback.format_exc()
    return JSONResponse(status_code=500, content=content)


@app.get("/health")
def health_check():
    import time
    from sqlalchemy.sql import text
    from app.db.session import SessionLocal
    
    start_time = time.time()
    db_status = "down"
    try:
        db = SessionLocal()
        db.execute(text("SELECT 1"))
        db.close()
        db_status = "up"
    except Exception as e:
        db_status = f"error: {str(e)}"
        
    process_time = round((time.time() - start_time) * 1000, 2)
    
    return {
        "status": "ok" if db_status == "up" else "degraded",
        "project": settings.PROJECT_NAME,
        "timestamp": datetime.utcnow().isoformat(),
        "database": db_status,
        "latency_ms": process_time,
        "active_sockets": len(_socket_sessions)
    }


os.makedirs("static", exist_ok=True)
os.makedirs("static/uploads", exist_ok=True)
app.mount("/", StaticFiles(directory="static", html=True), name="static")

if __name__ == "__main__":
    uvicorn.run("app.main:socket_app", host="0.0.0.0", port=8000, reload=True)
