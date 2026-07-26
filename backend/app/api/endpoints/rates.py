from fastapi import APIRouter
from typing import Dict

router = APIRouter()

# In-memory cache for the rates
current_rates = {
    "gold_22k": "Fetching...",
    "gold_24k": "Fetching...",
    "silver": "Fetching...",
    "diamond": "Fetching..."
}

@router.get("/", response_model=Dict[str, str])
def get_rates():
    """
    Retrieve live market rates for Gold, Silver, and Diamond.
    """
    return current_rates
