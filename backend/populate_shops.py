import os
import sys

# Add the app directory to the system path
sys.path.append(os.path.join(os.path.dirname(__file__), "app"))

from app.db.session import SessionLocal
from app.models.shop import Shop
from app.models.user import User
from app.models.user import Role

def populate():
    db = SessionLocal()
    # Ensure there is an admin user for author_id
    admin_role = db.query(Role).filter_by(name="Super Admin").first()
    if not admin_role:
        print("No super admin role found.")
        return
    
    admin_user = db.query(User).filter_by(role_id=admin_role.id).first()
    if not admin_user:
        print("No admin user found. Creating a dummy one.")
        # create dummy admin
        admin_user = User(email="dummyadmin@harur.local", hashed_password="xxx", role_id=admin_role.id, is_active=True)
        db.add(admin_user)
        db.commit()
        db.refresh(admin_user)

    from app.models.shop import ShopCategory
    
    # Create default categories
    cat_names = ["Bakery", "Clothing", "Grocery", "Medical", "Electronics"]
    cat_map = {}
    for cname in cat_names:
        cat = db.query(ShopCategory).filter_by(name=cname).first()
        if not cat:
            cat = ShopCategory(name=cname, icon="store")
            db.add(cat)
            db.commit()
            db.refresh(cat)
        cat_map[cname] = cat.id

    shops_data = [
        {
            "name": "Sri Lakshmi Bakery & Sweets",
            "description": "Famous for fresh cakes, sweets, and puffs near Harur Bus Stand.",
            "category_id": cat_map["Bakery"],
            "phone": "9876543210",
            "address": "Bazaar Street, Harur",
            "location_lat": 12.0625,
            "location_lng": 78.4895,
            "cover_url": "https://images.unsplash.com/photo-1509440159596-0249088772ff?w=500&q=80",
            "is_approved": True,
            "owner_id": admin_user.id
        },
        {
            "name": "Saravana Textiles",
            "description": "All varieties of men's, women's, and kids' clothing at wholesale prices.",
            "category_id": cat_map["Clothing"],
            "phone": "9876543211",
            "address": "Main Road, Harur",
            "location_lat": 12.0640,
            "location_lng": 78.4880,
            "cover_url": "https://images.unsplash.com/photo-1567401893414-76b7b1e5a7a5?w=500&q=80",
            "is_approved": True,
            "owner_id": admin_user.id
        },
        {
            "name": "Dharmapuri District Supermarket",
            "description": "One stop shop for all your grocery needs. Fresh produce and daily essentials.",
            "category_id": cat_map["Grocery"],
            "phone": "9876543212",
            "address": "By-pass Road, Harur",
            "location_lat": 12.0610,
            "location_lng": 78.4900,
            "cover_url": "https://images.unsplash.com/photo-1542838132-92c53300491e?w=500&q=80",
            "is_approved": True,
            "owner_id": admin_user.id
        },
        {
            "name": "Apollo Pharmacy Harur",
            "description": "24/7 medical shop providing genuine medicines and healthcare products.",
            "category_id": cat_map["Medical"],
            "phone": "9876543213",
            "address": "GH Road, Harur",
            "location_lat": 12.0650,
            "location_lng": 78.4850,
            "cover_url": "https://images.unsplash.com/photo-1585435557343-3b092031a831?w=500&q=80",
            "is_approved": True,
            "owner_id": admin_user.id
        },
        {
            "name": "Harur Electronics & Mobiles",
            "description": "Best deals on smartphones, accessories, and home appliances.",
            "category_id": cat_map["Electronics"],
            "phone": "9876543214",
            "address": "Katcheri Medu, Harur",
            "location_lat": 12.0630,
            "location_lng": 78.4870,
            "cover_url": "https://images.unsplash.com/photo-1519389950473-47ba0277781c?w=500&q=80",
            "is_approved": True,
            "owner_id": admin_user.id
        }
    ]

    for data in shops_data:
        existing = db.query(Shop).filter_by(name=data["name"]).first()
        if not existing:
            shop = Shop(**data)
            db.add(shop)
            print(f"Added {data['name']}")
        else:
            print(f"Skipped {data['name']} (already exists)")
    
    db.commit()
    db.close()
    print("Done populating shops.")

if __name__ == '__main__':
    populate()
