"""add volunteer_hours

Revision ID: 02e74cc7cf57
Revises: aabf7e289519
Create Date: 2026-07-29 13:09:23.441539

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '02e74cc7cf57'
down_revision: Union[str, Sequence[str], None] = 'aabf7e289519'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.add_column('profiles', sa.Column('volunteer_hours', sa.Integer(), server_default='0', nullable=True))


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_column('profiles', 'volunteer_hours')
