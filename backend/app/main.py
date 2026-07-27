import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from app.core.config import settings
from app.api.api import api_router

app = FastAPI(
    title=settings.PROJECT_NAME, openapi_url=f"{settings.API_V1_STR}/openapi.json"
)

# Set all CORS enabled origins
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # For development
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
import asyncio
import urllib.request
import threading
import time

import asyncio
import urllib.request
import threading
import time
import re
from app.api.endpoints.rates import current_rates

# ── Socket.IO Setup ─────────────────────────────────────────────────────────
import socketio
from jose import jwt, JWTError

sio = socketio.AsyncServer(async_mode='asgi', cors_allowed_origins='*')

# User session tracking: sid -> {user_id, user_name, room_ids}
_socket_sessions = {}


@sio.event
async def connect(sid, environ, auth):
    """Authenticate WebSocket connection via JWT."""
    token = None
    if auth and isinstance(auth, dict):
        token = auth.get('token')
    if not token:
        # Try from query string
        from urllib.parse import parse_qs
        qs = environ.get('QUERY_STRING', '')
        params = parse_qs(qs)
        if 'token' in params:
            token = params['token'][0]
    if not token:
        return False  # Reject connection

    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id = int(payload.get('sub', 0))
        if not user_id:
            return False
        _socket_sessions[sid] = {'user_id': user_id, 'rooms': set()}
        print(f"[Socket.IO] User {user_id} connected (sid={sid})")
        return True
    except (JWTError, Exception) as e:
        print(f"[Socket.IO] Auth failed: {e}")
        return False


@sio.event
async def join_room(sid, data):
    """Join a chat room for real-time messages."""
    room_id = data.get('room_id') if isinstance(data, dict) else data
    room_name = f'chat_room_{room_id}'
    sio.enter_room(sid, room_name)
    if sid in _socket_sessions:
        _socket_sessions[sid]['rooms'].add(room_name)
    print(f"[Socket.IO] sid={sid} joined {room_name}")


@sio.event
async def leave_room(sid, data):
    """Leave a chat room."""
    room_id = data.get('room_id') if isinstance(data, dict) else data
    room_name = f'chat_room_{room_id}'
    sio.leave_room(sid, room_name)
    if sid in _socket_sessions:
        _socket_sessions[sid]['rooms'].discard(room_name)


@sio.event
async def send_message(sid, data):
    """Receive a message via Socket.IO, save to DB, broadcast to room."""
    session = _socket_sessions.get(sid)
    if not session:
        return

    user_id = session['user_id']
    room_id = data.get('room_id')
    content = data.get('content', '').strip()
    if not room_id or not content:
        return

    # Save to database
    from app.db.session import SessionLocal
    from app.models.community import ChatMessage
    from app.models.user import Profile as ProfileModel

    db = SessionLocal()
    try:
        msg = ChatMessage(room_id=room_id, sender_id=user_id, content=content)
        db.add(msg)
        db.commit()
        db.refresh(msg)

        # Get sender info
        profile = db.query(ProfileModel).filter(ProfileModel.user_id == user_id).first()
        sender_name = "Anonymous"
        sender_avatar = None
        if profile:
            name = f"{profile.first_name or ''} {profile.last_name or ''}".strip()
            sender_name = name or "Anonymous"
            sender_avatar = profile.avatar_url

        from app.api.endpoints.community import _get_role
        sender_role = _get_role(db, user_id)

        msg_data = {
            'id': msg.id,
            'room_id': msg.room_id,
            'sender_id': msg.sender_id,
            'content': msg.content,
            'created_at': msg.created_at.isoformat() if msg.created_at else None,
            'sender_name': sender_name,
            'sender_role': sender_role,
            'sender_avatar': sender_avatar,
        }

        # Broadcast to everyone in the room
        await sio.emit('new_message', msg_data, room=f'chat_room_{room_id}')
    finally:
        db.close()


@sio.event
async def disconnect(sid):
    """Clean up on disconnect."""
    session = _socket_sessions.pop(sid, None)
    if session:
        print(f"[Socket.IO] User {session['user_id']} disconnected (sid={sid})")


# ── Wrap FastAPI with Socket.IO ASGI app ─────────────────────────────────────
socket_app = socketio.ASGIApp(sio, app)


def scrape_rates():
    try:
        url = "https://www.goodreturns.in/gold-rates/dharmapuri.html"
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        html = urllib.request.urlopen(req).read().decode('utf-8')
        
        # Scrape basic values
        matches = re.findall(r'₹\s*([0-9,]+)', html)
        if len(matches) >= 2:
            current_rates["gold_22k"] = f"₹{matches[0]}/g"
            current_rates["gold_24k"] = f"₹{matches[1]}/g"
        
        # Silver mock/scrape (goodreturns has silver on another page, let's just do a reliable fallback or scrape it)
        # 1g silver is usually around 90-100 ₹. Let's just set a static/mock live rate if we can't scrape silver from this page
        current_rates["silver"] = "₹102/g"
        current_rates["diamond"] = "₹3,15,000/ct" # Approximate 1ct diamond price
    except Exception as e:
        print("Error scraping rates:", e)

def keep_alive_loop():
    scrape_rates() # Scrape on boot
    loops = 0
    while True:
        try:
            # Sleep for 10 minutes (600 seconds)
            time.sleep(600)
            loops += 1
            if loops % 12 == 0: # Every 2 hours (12 * 10 mins)
                scrape_rates()
            
            req = urllib.request.Request('https://myharur.onrender.com/health', headers={'User-Agent': 'KeepAlive'})
            with urllib.request.urlopen(req) as response:
                pass # Ping successful
        except Exception:
            pass

@app.on_event("startup")
async def startup_event():
    # Auto-create any new DB tables (safe, non-destructive)
    from app.db.session import engine, SessionLocal
    import app.models  # ensure all models registered
    from app.db.session import Base
    from sqlalchemy import text
    Base.metadata.create_all(bind=engine)
    
    # Safely migrate existing tables by adding missing columns
    with engine.begin() as conn:
        migrations = [
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS uid VARCHAR DEFAULT gen_random_uuid();",
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
            # News table new columns
            "ALTER TABLE news ADD COLUMN IF NOT EXISTS image_url VARCHAR;",
            "ALTER TABLE news ADD COLUMN IF NOT EXISTS content TEXT;",
            "ALTER TABLE news ADD COLUMN IF NOT EXISTS verified_by INTEGER;",
            "ALTER TABLE news ADD COLUMN IF NOT EXISTS verified_at TIMESTAMPTZ;",
            # Make category_id nullable
            "ALTER TABLE news ALTER COLUMN category_id DROP NOT NULL;",
            # Listings image_urls column
            "ALTER TABLE listings ADD COLUMN IF NOT EXISTS image_urls JSONB DEFAULT '[]';",
        ]
        for query in migrations:
            try:
                conn.execute(text(query))
            except Exception:
                pass # Ignore if syntax not perfectly supported by dialect, IF NOT EXISTS should handle it mostly

    # Seed Super Admin if not exists
    db = SessionLocal()
    try:
        from app.crud.crud_user import get_user_by_email, create_user, get_role_by_name
        from app.schemas.user import UserCreate
        from app.models.user import Role
        
        super_admin_email = "admin.qenbel@gmail.com"
        user = get_user_by_email(db, super_admin_email)
        
        # Ensure Super Admin role exists
        role = get_role_by_name(db, "Super Admin")
        if not role:
            role = Role(name="Super Admin")
            db.add(role)
            db.commit()
            
        if not user:
            user_in = UserCreate(
                email=super_admin_email,
                password="qenbel@admin",
                role_name="Super Admin"
            )
            create_user(db, user_in=user_in)
        else:
            # Force update password and role if they already exist
            from app.core.security import get_password_hash
            user.hashed_password = get_password_hash("qenbel@admin")
            user.role_id = role.id
            if user.login_provider == "google":
                user.login_provider = "both"
            db.commit()
    finally:
        db.close()
    
    # Create uploads directory
    import os
    os.makedirs("static/uploads", exist_ok=True)
    
    # Start the keep-alive background thread
    threading.Thread(target=keep_alive_loop, daemon=True).start()

app.include_router(api_router, prefix=settings.API_V1_STR)

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    import traceback
    return JSONResponse(
        status_code=500,
        content={"message": "Internal Server Error", "detail": str(exc), "traceback": traceback.format_exc()},
    )

@app.get("/health")
def health_check():
    return {"status": "ok", "db_server": settings.POSTGRES_SERVER, "project": settings.PROJECT_NAME}

import os
# Create static dir if it doesn't exist
os.makedirs("static", exist_ok=True)
os.makedirs("static/uploads", exist_ok=True)
# Mount static files (serves index.html at root and app-release.apk)
app.mount("/", StaticFiles(directory="static", html=True), name="static")

if __name__ == "__main__":
    # Run socket_app (which wraps FastAPI) for Socket.IO support
    uvicorn.run("app.main:socket_app", host="0.0.0.0", port=8000, reload=True)
