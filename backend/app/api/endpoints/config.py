from fastapi import APIRouter
from pydantic import BaseModel

router = APIRouter()

class AppConfig(BaseModel):
    min_version: str
    latest_version: str
    update_url: str

@router.get("/", response_model=AppConfig)
def get_config():
    """
    Retrieve application config (versioning, update urls, etc.)
    """
    return AppConfig(
        min_version="1.0.0",
        latest_version="1.0.0",
        update_url="https://myharur.onrender.com/myharur.apk"
    )
