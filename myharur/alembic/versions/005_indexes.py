"""005_indexes

Revision ID: 005_indexes
Revises: 004_enable_rls
Create Date: 2026-08-11

"""
from alembic import op

revision = '005_indexes'
down_revision = '004_enable_rls'
branch_labels = None
depends_on = None


def upgrade():
    op.execute("""
    DO $$
    BEGIN
      IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'myharur' AND table_name = 'emergencies' AND column_name = 'mmid') THEN
        CREATE INDEX IF NOT EXISTS idx_emergency_mmid ON myharur.emergencies(mmid);
      END IF;

      IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'myharur' AND table_name = 'emergencies' AND column_name = 'status') THEN
        CREATE INDEX IF NOT EXISTS idx_emergency_status ON myharur.emergencies(status) WHERE status = 'active';
      END IF;

      IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'myharur' AND table_name = 'news' AND column_name = 'created_at') THEN
        CREATE INDEX IF NOT EXISTS idx_news_created ON myharur.news(created_at DESC);
      END IF;

      IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'myharur' AND table_name = 'chat_messages' AND column_name = 'room_id') THEN
        CREATE INDEX IF NOT EXISTS idx_chat_messages_room ON myharur.chat_messages(room_id);
      END IF;

      IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'myharur' AND table_name = 'orders' AND column_name = 'mmid') THEN
        CREATE INDEX IF NOT EXISTS idx_orders_mmid ON myharur.orders(mmid);
      END IF;

      IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'myharur' AND table_name = 'profiles' AND column_name = 'mmid') THEN
        CREATE INDEX IF NOT EXISTS idx_profiles_mmid ON myharur.profiles(mmid);
      END IF;
    END $$;
    """)


def downgrade():
    pass
