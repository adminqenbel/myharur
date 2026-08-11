"""003_migrate_tables

Revision ID: 003_migrate_tables
Revises: 002_create_accounts
Create Date: 2026-08-11

"""
from alembic import op

revision = '003_migrate_tables'
down_revision = '002_create_accounts'
branch_labels = None
depends_on = None

# List of all MyHarur domain tables
DOMAIN_TABLES = [
    'profiles', 'roles', 'user_roles', 'permissions', 'role_permissions', 'username_history',
    'shops', 'shop_categories', 'shop_offers', 'products', 'shop_images', 'restaurant_rankings',
    'news', 'news_categories', 'news_images', 'comments', 'likes', 'duplicate_groups', 'news_archive',
    'news_sources', 'crawler_logs', 'raw_articles',
    'emergencies', 'emergency_requests', 'nearby_help', 'volunteers', 'government_officials',
    'marketplace_listings', 'job_listings', 'job_postings', 'listings',
    'events', 'event_tickets', 'orders', 'tournaments', 'tournament_teams', 'tournament_fixtures',
    'polls', 'poll_options', 'poll_votes', 'questions', 'answers',
    'chat_rooms', 'chat_messages', 'chat_sessions', 'knowledge_base', 'faqs', 'command_history', 'intent_logs',
    'support_tickets', 'user_reputation', 'leaderboard_snapshots',
    'states', 'districts', 'taluks', 'towns', 'villages', 'weather_logs', 'donations',
    'system_settings', 'advertisements', 'notification_queue', 'reports', 'download_logs',
    'deletion_requests', 'audit_logs', 'access_codes'
]

# Tables containing user_id or buyer_id reference
USER_REFERENCING_TABLES = [
    'profiles', 'user_roles', 'username_history', 'emergencies', 'emergency_requests',
    'nearby_help', 'volunteers', 'government_officials', 'marketplace_listings', 'job_listings',
    'job_postings', 'events', 'event_tickets', 'orders', 'comments', 'likes', 'questions',
    'answers', 'chat_sessions', 'command_history', 'intent_logs', 'audit_logs', 'reports',
    'deletion_requests', 'donations', 'poll_votes', 'user_reputation', 'leaderboard_snapshots',
    'support_tickets', 'tournaments'
]


def upgrade():
    sql = []
    
    # 1. Move tables from public to myharur schema if they exist in public
    for table in DOMAIN_TABLES:
        sql.append(f"""
        DO $$
        BEGIN
          IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = '{table}') THEN
            ALTER TABLE public.{table} SET SCHEMA myharur;
          END IF;
        END $$;
        """)

    # 2. Add mmid column and populate from legacy mapping
    for table in USER_REFERENCING_TABLES:
        sql.append(f"""
        DO $$
        BEGIN
          IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'myharur' AND table_name = '{table}') THEN
            ALTER TABLE myharur.{table} ADD COLUMN IF NOT EXISTS mmid UUID REFERENCES myharur.accounts(mmid);
            
            IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'myharur' AND table_name = '{table}' AND column_name = 'user_id') THEN
              UPDATE myharur.{table} t
              SET mmid = m.new_mmid
              FROM myharur.legacy_user_mapping m
              WHERE t.user_id = m.old_user_id AND t.mmid IS NULL;
            END IF;
          END IF;
        END $$;
        """)

    op.execute("\n".join(sql))


def downgrade():
    pass
