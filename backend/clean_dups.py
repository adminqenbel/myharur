from app.db.session import SessionLocal
from app.models.marketplace import MarketplaceListing
from sqlalchemy import func

def delete_duplicates():
    db = SessionLocal()
    
    # Find minimum IDs for each (title, price) combination
    min_ids_query = db.query(func.min(MarketplaceListing.id).label('min_id')).group_by(MarketplaceListing.title, MarketplaceListing.price).subquery()
    
    # Delete all other rows
    deleted = db.query(MarketplaceListing).filter(MarketplaceListing.id.not_in(min_ids_query)).delete(synchronize_session=False)
    
    db.commit()
    print(f"Deleted {deleted} duplicate items.")
    db.close()

if __name__ == '__main__':
    delete_duplicates()
