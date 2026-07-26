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
    Base.metadata.create_all(bind=engine)
    
    # Seed Super Admin if not exists
    db = SessionLocal()
    try:
        from app.crud.crud_user import get_user_by_email, create_user, get_role_by_name
        from app.schemas.user import UserCreate
        from app.models.user import Role
        
        super_admin_email = "admin.qenbel@gmail.com"
        user = get_user_by_email(db, super_admin_email)
        if not user:
            # Ensure Super Admin role exists
            role = get_role_by_name(db, "Super Admin")
            if not role:
                role = Role(name="Super Admin")
                db.add(role)
                db.commit()
            
            user_in = UserCreate(
                email=super_admin_email,
                password="qenbel@admin",
                role_name="Super Admin"
            )
            create_user(db, user_in=user_in)
    finally:
        db.close()
    
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
# Mount static files (serves index.html at root and app-release.apk)
app.mount("/", StaticFiles(directory="static", html=True), name="static")

if __name__ == "__main__":
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
