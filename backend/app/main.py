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

def keep_alive_loop():
    while True:
        try:
            # Sleep for 10 minutes (600 seconds)
            time.sleep(600)
            req = urllib.request.Request('https://myharur.onrender.com/health', headers={'User-Agent': 'KeepAlive'})
            with urllib.request.urlopen(req) as response:
                pass # Ping successful
        except Exception:
            pass

@app.on_event("startup")
async def startup_event():
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
