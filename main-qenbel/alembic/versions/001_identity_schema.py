"""001_identity_schema

Revision ID: 001_identity_schema
Revises: 
Create Date: 2026-08-11

"""
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = '001_identity_schema'
down_revision = None
branch_labels = None
depends_on = None


def upgrade():
    op.execute("""
    -- 1. Create schema
    CREATE SCHEMA IF NOT EXISTS qenbel_identity;

    -- 2. Accounts — global identity anchor
    CREATE TABLE IF NOT EXISTS qenbel_identity.accounts (
      qenbel_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      email_normalized TEXT UNIQUE NOT NULL,
      display_name     TEXT,
      avatar_url       TEXT,
      status           TEXT NOT NULL DEFAULT 'active'
                       CHECK (status IN ('active', 'suspended', 'deleted')),
      created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    CREATE OR REPLACE FUNCTION qenbel_identity.set_updated_at()
    RETURNS TRIGGER AS $$
    BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
    $$ LANGUAGE plpgsql;

    DROP TRIGGER IF EXISTS accounts_updated_at ON qenbel_identity.accounts;
    CREATE TRIGGER accounts_updated_at
      BEFORE UPDATE ON qenbel_identity.accounts
      FOR EACH ROW EXECUTE FUNCTION qenbel_identity.set_updated_at();

    -- 3. OAuth provider linkage
    CREATE TABLE IF NOT EXISTS qenbel_identity.oauth_identities (
      id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      qenbel_id        UUID NOT NULL
                       REFERENCES qenbel_identity.accounts(qenbel_id)
                       ON DELETE CASCADE,
      provider         TEXT NOT NULL CHECK (provider IN ('google')),
      provider_user_id TEXT NOT NULL,
      provider_email   TEXT,
      linked_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      UNIQUE (provider, provider_user_id)
    );
    CREATE INDEX IF NOT EXISTS idx_oauth_qenbel_id ON qenbel_identity.oauth_identities(qenbel_id);

    -- 4. Refresh token sessions
    CREATE TABLE IF NOT EXISTS qenbel_identity.sessions (
      session_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      qenbel_id          UUID NOT NULL
                         REFERENCES qenbel_identity.accounts(qenbel_id)
                         ON DELETE CASCADE,
      refresh_token_hash TEXT NOT NULL UNIQUE,
      issued_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      expires_at         TIMESTAMPTZ NOT NULL,
      revoked            BOOLEAN NOT NULL DEFAULT FALSE,
      user_agent         TEXT,
      ip_address         INET
    );
    CREATE INDEX IF NOT EXISTS idx_sessions_qenbel_id ON qenbel_identity.sessions(qenbel_id);
    CREATE INDEX IF NOT EXISTS idx_sessions_expires_at ON qenbel_identity.sessions(expires_at);

    -- 5. Product registry
    CREATE TABLE IF NOT EXISTS qenbel_identity.product_registry (
      product_id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      product_slug          TEXT UNIQUE NOT NULL,
      product_name          TEXT NOT NULL,
      service_url           TEXT NOT NULL,
      provisioning_config   JSONB NOT NULL DEFAULT '{}',
      is_active             BOOLEAN NOT NULL DEFAULT TRUE,
      created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    INSERT INTO qenbel_identity.product_registry
      (product_slug, product_name, service_url)
    VALUES
      ('myharur', 'MyHarur', 'https://myharur.onrender.com')
    ON CONFLICT (product_slug) DO NOTHING;

    -- 6. Product memberships
    CREATE TABLE IF NOT EXISTS qenbel_identity.product_memberships (
      membership_id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      qenbel_id       UUID NOT NULL
                      REFERENCES qenbel_identity.accounts(qenbel_id)
                      ON DELETE CASCADE,
      product_slug    TEXT NOT NULL
                      REFERENCES qenbel_identity.product_registry(product_slug),
      product_user_id TEXT NOT NULL,
      provisioned_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      UNIQUE (qenbel_id, product_slug)
    );
    CREATE INDEX IF NOT EXISTS idx_memberships_qenbel_id
      ON qenbel_identity.product_memberships(qenbel_id);

    -- 7. RLS: lock identity schema down
    ALTER TABLE qenbel_identity.accounts ENABLE ROW LEVEL SECURITY;
    ALTER TABLE qenbel_identity.oauth_identities ENABLE ROW LEVEL SECURITY;
    ALTER TABLE qenbel_identity.sessions ENABLE ROW LEVEL SECURITY;
    ALTER TABLE qenbel_identity.product_registry ENABLE ROW LEVEL SECURITY;
    ALTER TABLE qenbel_identity.product_memberships ENABLE ROW LEVEL SECURITY;
    """)


def downgrade():
    op.execute("""
    DROP TABLE IF EXISTS qenbel_identity.product_memberships;
    DROP TABLE IF EXISTS qenbel_identity.product_registry;
    DROP TABLE IF EXISTS qenbel_identity.sessions;
    DROP TABLE IF EXISTS qenbel_identity.oauth_identities;
    DROP TABLE IF EXISTS qenbel_identity.accounts;
    DROP FUNCTION IF EXISTS qenbel_identity.set_updated_at();
    DROP SCHEMA IF EXISTS qenbel_identity CASCADE;
    """)
