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
        },
        {
            "name": "Vasantham Furniture",
            "description": "Premium wood and plastic furniture for home and office.",
            "category_id": cat_map["Electronics"], # Closest category
            "phone": "9876543215",
            "address": "Salem By-pass, Harur",
            "location_lat": 12.0660,
            "location_lng": 78.4840,
            "cover_url": "https://images.unsplash.com/photo-1524758631624-e2822e304c36?w=500&q=80",
            "is_approved": True,
            "owner_id": admin_user.id
        },
        {
            "name": "Arun Ice Creams",
            "description": "Cool down with delicious ice creams, shakes, and falooda.",
            "category_id": cat_map["Bakery"],
            "phone": "9876543216",
            "address": "Gandhi Road, Harur",
            "location_lat": 12.0615,
            "location_lng": 78.4905,
            "cover_url": "https://images.unsplash.com/photo-1558500222-1d371ba21cba?w=500&q=80",
            "is_approved": True,
            "owner_id": admin_user.id
        },
        {
            "name": "Kannan Departmental Store",
            "description": "Wholesale and retail grocery store with fresh stocks daily.",
            "category_id": cat_map["Grocery"],
            "phone": "9876543217",
            "address": "Dharmapuri Road, Harur",
            "location_lat": 12.0600,
            "location_lng": 78.4920,
            "cover_url": "https://images.unsplash.com/photo-1578916171728-46686eac8d58?w=500&q=80",
            "is_approved": True,
            "owner_id": admin_user.id
        },
        {
            "name": "Bharath Pharmacy",
            "description": "Reliable medical store with surgicals and baby care products.",
            "category_id": cat_map["Medical"],
            "phone": "9876543218",
            "address": "Near Govt Hospital, Harur",
            "location_lat": 12.0645,
            "location_lng": 78.4860,
            "cover_url": "https://images.unsplash.com/photo-1587854692152-cbe660dbde88?w=500&q=80",
            "is_approved": True,
            "owner_id": admin_user.id
        },
        {
            "name": "Fashion Hub",
            "description": "Trendy clothes for teenagers and kids. New arrivals every week.",
            "category_id": cat_map["Clothing"],
            "phone": "9876543219",
            "address": "Bazaar Street, Harur",
            "location_lat": 12.0635,
            "location_lng": 78.4885,
            "cover_url": "https://images.unsplash.com/photo-1441984904996-e0b6ba687e04?w=500&q=80",
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
