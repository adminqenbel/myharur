import sys
import os

# Add backend to sys.path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from sqlalchemy import text
from app.db.session import engine, Base
from app.models import user, community, gamification, support, emergency_platform, marketplace, ingestion, admin

def main():
    print("Creating missing tables...")
    Base.metadata.create_all(bind=engine)
    
    print("Adding missing columns to existing tables...")
    queries = [
        "ALTER TABLE profiles ADD COLUMN volunteer_hours INTEGER DEFAULT 0;",
        "ALTER TABLE chat_rooms ADD COLUMN is_secure BOOLEAN DEFAULT FALSE;",
        "ALTER TABLE chat_messages ADD COLUMN is_voice_note BOOLEAN DEFAULT FALSE;",
        "ALTER TABLE chat_messages ADD COLUMN audio_url VARCHAR;",
        "ALTER TABLE events ADD COLUMN is_paid BOOLEAN DEFAULT FALSE;",
        "ALTER TABLE events ADD COLUMN ticket_price FLOAT DEFAULT 0.0;",
        "ALTER TABLE events ADD COLUMN current_attendees INTEGER DEFAULT 0;",
        "ALTER TABLE emergencies ADD COLUMN radius_km FLOAT DEFAULT 1.0;"
    ]
    
    with engine.begin() as conn:
        for q in queries:
            try:
                conn.execute(text(q))
                print(f"Successfully executed: {q}")
            except Exception as e:
                print(f"Skipped (likely already exists): {q} - Error: {e}")
                
if __name__ == "__main__":
    main()
