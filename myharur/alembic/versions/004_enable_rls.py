"""004_enable_rls

Revision ID: 004_enable_rls
Revises: 003_migrate_tables
Create Date: 2026-08-11

"""
from alembic import op

revision = '004_enable_rls'
down_revision = '003_migrate_tables'
branch_labels = None
depends_on = None

PUBLIC_READ_TABLES = [
    'news', 'news_categories', 'shops', 'shop_categories', 'products',
    'marketplace_listings', 'job_listings', 'events', 'polls',
    'states', 'districts', 'taluks', 'towns', 'villages', 'faqs'
]

PROTECTED_TABLES = [
    'profiles', 'emergencies', 'orders', 'comments', 'likes', 'chat_messages',
    'user_reputation', 'support_tickets', 'donations', 'volunteers'
]


def upgrade():
    sql = []
    
    # 1. Enable RLS and define owner policies for protected tables
    for table in PROTECTED_TABLES:
        sql.append(f"""
        DO $$
        BEGIN
          IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'myharur' AND table_name = '{table}') THEN
            ALTER TABLE myharur.{table} ENABLE ROW LEVEL SECURITY;
            
            IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'myharur' AND table_name = '{table}' AND column_name = 'mmid') THEN
              DROP POLICY IF EXISTS owner_access ON myharur.{table};
              CREATE POLICY owner_access ON myharur.{table}
                USING (mmid = current_setting('app.current_mmid', TRUE)::uuid);
            END IF;
          END IF;
        END $$;
        """)

    # 2. Public read policies + owner write policies
    for table in PUBLIC_READ_TABLES:
        sql.append(f"""
        DO $$
        BEGIN
          IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'myharur' AND table_name = '{table}') THEN
            ALTER TABLE myharur.{table} ENABLE ROW LEVEL SECURITY;
            
            DROP POLICY IF EXISTS public_read ON myharur.{table};
            CREATE POLICY public_read ON myharur.{table}
              FOR SELECT USING (TRUE);
              
            IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'myharur' AND table_name = '{table}' AND column_name = 'mmid') THEN
              DROP POLICY IF EXISTS owner_write ON myharur.{table};
              CREATE POLICY owner_write ON myharur.{table}
                FOR INSERT WITH CHECK (mmid = current_setting('app.current_mmid', TRUE)::uuid);
            END IF;
          END IF;
        END $$;
        """)

    op.execute("\n".join(sql))


def downgrade():
    pass
