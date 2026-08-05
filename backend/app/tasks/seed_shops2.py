import logging
from dotenv import load_dotenv
load_dotenv()
from app.db.session import SessionLocal
from app.models.shop import Shop, ShopCategory

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def seed_shops():
    db = SessionLocal()
    try:
        default_cat = db.query(ShopCategory).filter(ShopCategory.name == 'General').first()
        if not default_cat:
            default_cat = ShopCategory(name='General', icon='store')
            db.add(default_cat)
            db.flush()

        shops_data = [
            {'name': 'Harur Supermarket', 'description': 'General goods and groceries', 'lat': 12.0628, 'lng': 78.4950},
            {'name': 'Dharmapuri Electronics', 'description': 'Electronics and mobiles', 'lat': 12.1261, 'lng': 78.1581},
            {'name': 'Harur Textiles', 'description': 'Clothing and apparel', 'lat': 12.0650, 'lng': 78.4920},
            {'name': 'Dharmapuri Bakery', 'description': 'Cakes, sweets and snacks', 'lat': 12.1300, 'lng': 78.1600}
        ]

        for s in shops_data:
            existing = db.query(Shop).filter(Shop.name == s['name']).first()
            if not existing:
                new_shop = Shop(
                    name=s['name'],
                    description=s['description'],
                    category_id=default_cat.id,
                    location_lat=s['lat'],
                    location_lng=s['lng'],
                    is_approved=True,
                    is_verified=True,
                    is_open=True
                )
                db.add(new_shop)

        db.commit()
        logger.info('Seeded shops successfully')
    except Exception as e:
        logger.error(f'Failed to seed: {e}')
    finally:
        db.close()

if __name__ == '__main__':
    seed_shops()
