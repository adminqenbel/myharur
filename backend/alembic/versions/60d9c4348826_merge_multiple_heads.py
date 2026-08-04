"""Merge multiple heads

Revision ID: 60d9c4348826
Revises: 9f8g7h6i5j4k, c2d3e4f5a6b7
Create Date: 2026-08-04 18:27:57.692658

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '60d9c4348826'
down_revision: Union[str, Sequence[str], None] = ('9f8g7h6i5j4k', 'c2d3e4f5a6b7')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    pass


def downgrade() -> None:
    """Downgrade schema."""
    pass
