"""phase 8 events and ticketing

Revision ID: 5e6f7g8h9i0j
Revises: 4d5e6f7g8h9i
Create Date: 2026-07-31 15:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.engine.reflection import Inspector


# revision identifiers, used by Alembic.
revision: str = '5e6f7g8h9i0j'
down_revision: Union[str, Sequence[str], None] = '4d5e6f7g8h9i'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    conn = op.get_bind()
    inspector = Inspector.from_engine(conn)
    tables = inspector.get_table_names()

    # Add new columns to events if they don't exist
    columns = [c['name'] for c in inspector.get_columns('events')]
    if 'is_featured' not in columns:
        op.add_column('events', sa.Column('is_featured', sa.Boolean(), server_default='false', nullable=True))
    if 'is_paid' not in columns:
        op.add_column('events', sa.Column('is_paid', sa.Boolean(), server_default='false', nullable=True))
    if 'ticket_price' not in columns:
        op.add_column('events', sa.Column('ticket_price', sa.Float(), nullable=True))
    if 'current_attendees' not in columns:
        op.add_column('events', sa.Column('current_attendees', sa.Integer(), server_default='0', nullable=True))

    if 'event_tickets' not in tables:
        op.create_table(
            'event_tickets',
            sa.Column('id', sa.Integer(), nullable=False),
            sa.Column('event_id', sa.Integer(), nullable=False),
            sa.Column('user_id', sa.Integer(), nullable=False),
            sa.Column('qr_code_data', sa.String(), nullable=False),
            sa.Column('status', sa.String(), server_default='valid', nullable=True),
            sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
            sa.ForeignKeyConstraint(['event_id'], ['events.id'], ),
            sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
            sa.PrimaryKeyConstraint('id'),
            sa.UniqueConstraint('qr_code_data')
        )
        op.create_index(op.f('ix_event_tickets_id'), 'event_tickets', ['id'], unique=False)


def downgrade() -> None:
    op.drop_index(op.f('ix_event_tickets_id'), table_name='event_tickets')
    op.drop_table('event_tickets')
    op.drop_column('events', 'current_attendees')
    op.drop_column('events', 'ticket_price')
    op.drop_column('events', 'is_paid')
    op.drop_column('events', 'is_featured')
