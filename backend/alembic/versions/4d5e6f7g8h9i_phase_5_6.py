"""phase 5 marketplace and phase 6 emergency

Revision ID: 4d5e6f7g8h9i
Revises: 3c4d5e6f7g8h
Create Date: 2026-07-31 14:45:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.engine.reflection import Inspector


# revision identifiers, used by Alembic.
revision: str = '4d5e6f7g8h9i'
down_revision: Union[str, Sequence[str], None] = '3c4d5e6f7g8h'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    conn = op.get_bind()
    inspector = Inspector.from_engine(conn)
    tables = inspector.get_table_names()

    if 'marketplace_listings' not in tables:
        op.create_table(
            'marketplace_listings',
            sa.Column('id', sa.Integer(), nullable=False),
            sa.Column('user_id', sa.Integer(), nullable=False),
            sa.Column('type', sa.String(), nullable=False), # business, community_used, community_new, jobs, rental
            sa.Column('title', sa.String(), nullable=False),
            sa.Column('description', sa.Text(), nullable=True),
            sa.Column('price', sa.Float(), nullable=True),
            sa.Column('status', sa.String(), server_default='active', nullable=True),
            sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
            sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
            sa.PrimaryKeyConstraint('id')
        )

    if 'emergencies' not in tables:
        op.create_table(
            'emergencies',
            sa.Column('id', sa.Integer(), nullable=False),
            sa.Column('user_id', sa.Integer(), nullable=False),
            sa.Column('type', sa.String(), nullable=False), # citizen_sos, govt_grievance
            sa.Column('category', sa.String(), nullable=False), # blood, medical, road, water
            sa.Column('status', sa.String(), server_default='created', nullable=False), # created, assigned, in_progress, resolved
            sa.Column('lat', sa.Float(), nullable=True),
            sa.Column('lng', sa.Float(), nullable=True),
            sa.Column('radius_escalation', sa.Integer(), server_default='1', nullable=True),
            sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
            sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
            sa.PrimaryKeyConstraint('id')
        )


def downgrade() -> None:
    op.drop_table('emergencies')
    op.drop_table('marketplace_listings')
