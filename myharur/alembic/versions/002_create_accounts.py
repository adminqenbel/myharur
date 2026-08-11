"""002_create_accounts

Revision ID: 002_create_accounts
Revises: 001_create_myharur_schema
Create Date: 2026-08-11

"""
from alembic import op
import sqlalchemy as sa

revision = '002_create_accounts'
down_revision = '001_create_myharur_schema'
branch_labels = None
depends_on = None


def upgrade():
    op.execute("""
    -- Canonical accounts table for MyHarur
    CREATE TABLE IF NOT EXISTS myharur.accounts (
      mmid                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      qenbel_id           UUID UNIQUE NOT NULL,
      provisioned_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      last_seen_at        TIMESTAMPTZ,
      status              TEXT NOT NULL DEFAULT 'active'
                          CHECK (status IN ('active', 'suspended', 'deleted')),
      onboarding_complete BOOLEAN NOT NULL DEFAULT FALSE
    );

    CREATE INDEX IF NOT EXISTS idx_myharur_accounts_qenbel_id
      ON myharur.accounts(qenbel_id);

    -- Legacy user mapping table during migration
    CREATE TABLE IF NOT EXISTS myharur.legacy_user_mapping (
      old_user_id INTEGER NOT NULL,
      new_mmid    UUID NOT NULL REFERENCES myharur.accounts(mmid),
      migrated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      PRIMARY KEY (old_user_id)
    );

    -- Populate accounts and mapping if public.users exists
    DO $$
    BEGIN
      IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'users') THEN
        INSERT INTO myharur.accounts (mmid, qenbel_id, provisioned_at)
        SELECT
          gen_random_uuid() AS mmid,
          gen_random_uuid() AS qenbel_id,
          COALESCE(created_at, NOW()) AS provisioned_at
        FROM public.users
        ON CONFLICT (qenbel_id) DO NOTHING;

        INSERT INTO myharur.legacy_user_mapping (old_user_id, new_mmid)
        SELECT u.id, a.mmid
        FROM public.users u
        JOIN myharur.accounts a ON TRUE
        ON CONFLICT (old_user_id) DO NOTHING;
      END IF;
    END $$;
    """)


def downgrade():
    op.execute("""
    DROP TABLE IF EXISTS myharur.legacy_user_mapping;
    DROP TABLE IF EXISTS myharur.accounts;
    """)
