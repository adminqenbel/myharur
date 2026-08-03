import httpx
import logging
from app.db.session import SessionLocal
from app.models.shop import Shop, ShopCategory
from sqlalchemy.orm import Session
from sqlalchemy.exc import OperationalError

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def scrape_and_store_shops():
    logger.info("Starting shop scraping using OpenStreetMap Overpass API for Harur...")
    overpass_url = "http://overpass-api.de/api/interpreter"
    
    # Bounding box for Harur (approx)
    query = """
    [out:json][timeout:25];
    nwr["shop"](12.03, 78.46, 12.09, 78.51);
    out center;
    """
    
    try:
        headers = {"User-Agent": "MyHarurApp/1.0 (admin@myharur.com)"}
        response = httpx.post(overpass_url, data={'data': query}, headers=headers, timeout=30)
        response.raise_for_status()
        data = response.json()
    except Exception as e:
        logger.error(f"Failed to fetch data from Overpass API: {e}")
        return

    elements = data.get("elements", [])
    logger.info(f"Found {len(elements)} shops in OpenStreetMap.")

    if not elements:
        return

    db: Session = SessionLocal()
    try:
        # Create a default category if none exists
        default_cat = db.query(ShopCategory).filter(ShopCategory.name == "General").first()
        if not default_cat:
            default_cat = ShopCategory(name="General", icon="store")
            db.add(default_cat)
            db.flush()

        for el in elements:
            tags = el.get("tags", {})
            name = tags.get("name") or tags.get("name:en")
            if not name:
                continue

            shop_type = tags.get("shop", "General")
            description = f"{shop_type.capitalize()} shop in Harur."
            phone = tags.get("phone") or tags.get("contact:phone")
            opening_hours = tags.get("opening_hours")
            lat = el.get("lat") or (el.get("center", {}).get("lat"))
            lon = el.get("lon") or (el.get("center", {}).get("lon"))

            # Check if shop already exists
            existing_shop = db.query(Shop).filter(Shop.name == name).first()
            if existing_shop:
                # Update existing
                existing_shop.description = description
                existing_shop.phone = phone
                existing_shop.opening_hours = opening_hours
                if lat and lon:
                    existing_shop.location_lat = lat
                    existing_shop.location_lng = lon
                existing_shop.is_approved = True # Auto-approve scraped shops
                continue
            
            # Create new
            new_shop = Shop(
                name=name,
                description=description,
                category_id=default_cat.id,
                location_lat=lat,
                location_lng=lon,
                phone=phone,
                opening_hours=opening_hours,
                is_approved=True,
                is_verified=True,
                is_open=True
            )
            db.add(new_shop)

        db.commit()
        logger.info("Successfully saved scraped shops to database.")
    except OperationalError as e:
        logger.error("Database connection failed. Is Supabase paused? Error: " + str(e))
    except Exception as e:
        logger.error(f"Error saving to database: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    scrape_and_store_shops()
