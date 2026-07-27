from fastapi import APIRouter
from typing import Dict, Any, Optional

router = APIRouter()

# In-memory cache for rates - updated by background scraper in main.py
current_rates: Dict[str, Any] = {
    "gold_22k": "Fetching...",
    "gold_24k": "Fetching...",
    "gold_22k_raw": 0,
    "gold_24k_raw": 0,
    "gold_22k_prev": None,
    "gold_24k_prev": None,
    "gold_22k_trend": "→",
    "gold_24k_trend": "→",
    "silver": "Fetching...",
    "diamond": "₹3,15,000/ct",
    "updated_at": None,
}


@router.get("/")
def get_rates() -> Dict[str, Any]:
    """Retrieve live market rates for Gold, Silver, and Diamond with trend data."""
    return {
        "gold_22k": current_rates.get("gold_22k", "N/A"),
        "gold_24k": current_rates.get("gold_24k", "N/A"),
        "gold_22k_prev": current_rates.get("gold_22k_prev"),
        "gold_24k_prev": current_rates.get("gold_24k_prev"),
        "gold_22k_trend": current_rates.get("gold_22k_trend", "→"),
        "gold_24k_trend": current_rates.get("gold_24k_trend", "→"),
        "silver": current_rates.get("silver", "N/A"),
        "diamond": current_rates.get("diamond", "N/A"),
        "updated_at": current_rates.get("updated_at"),
    }
