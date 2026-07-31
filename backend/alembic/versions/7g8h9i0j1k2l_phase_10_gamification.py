"""phase 10 gamification

Revision ID: 7g8h9i0j1k2l
Revises: 6f7g8h9i0j1k
Create Date: 2026-07-31 15:10:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.engine.reflection import Inspector


# revision identifiers, used by Alembic.
revision: str = '7g8h9i0j1k2l'
down_revision: Union[str, Sequence[str], None] = '6f7g8h9i0j1k'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    conn = op.get_bind()
    inspector = Inspector.from_engine(conn)
    tables = inspector.get_table_names()

    if 'user_reputation' not in tables:
        op.create_table(
            'user_reputation',
            sa.Column('id', sa.Integer(), nullable=False),
            sa.Column('user_id', sa.Integer(), nullable=False),
            sa.Column('upvotes', sa.Integer(), server_default='0', nullable=True),
            sa.Column('downvotes', sa.Integer(), server_default='0', nullable=True),
            sa.Column('helpful_answers', sa.Integer(), server_default='0', nullable=True),
            sa.Column('events_attended', sa.Integer(), server_default='0', nullable=True),
            sa.Column('reputation_score', sa.Float(), server_default='0.0', nullable=True),
            sa.Column('tier_badge', sa.String(), server_default='Bronze', nullable=True),
            sa.Column('updated_at', sa.DateTime(timezone=True), nullable=True),
            sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
            sa.PrimaryKeyConstraint('id'),
            sa.UniqueConstraint('user_id')
        )
        op.create_index(op.f('ix_user_reputation_id'), 'user_reputation', ['id'], unique=False)


def downgrade() -> None:
    op.drop_index(op.f('ix_user_reputation_id'), table_name='user_reputation')
    op.drop_table('user_reputation')
