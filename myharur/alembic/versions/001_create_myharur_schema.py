"""001_create_myharur_schema

Revision ID: 001_create_myharur_schema
Revises: 
Create Date: 2026-08-11

"""
from alembic import op
import sqlalchemy as sa

revision = '001_create_myharur_schema'
down_revision = None
branch_labels = None
depends_on = None


def upgrade():
    op.execute("""
    CREATE SCHEMA IF NOT EXISTS myharur;
    SET search_path = myharur, public;
    """)


def downgrade():
    op.execute("""
    DROP SCHEMA IF EXISTS myharur CASCADE;
    """)
