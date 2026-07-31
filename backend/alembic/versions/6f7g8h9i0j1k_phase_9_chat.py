"""phase 9 chat audio and secure

Revision ID: 6f7g8h9i0j1k
Revises: 5e6f7g8h9i0j
Create Date: 2026-07-31 15:05:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.engine.reflection import Inspector


# revision identifiers, used by Alembic.
revision: str = '6f7g8h9i0j1k'
down_revision: Union[str, Sequence[str], None] = '5e6f7g8h9i0j'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    conn = op.get_bind()
    inspector = Inspector.from_engine(conn)
    
    chat_rooms_cols = [c['name'] for c in inspector.get_columns('chat_rooms')]
    if 'is_secure' not in chat_rooms_cols:
        op.add_column('chat_rooms', sa.Column('is_secure', sa.Boolean(), server_default='false', nullable=True))
        
    chat_msgs_cols = [c['name'] for c in inspector.get_columns('chat_messages')]
    if 'is_voice_note' not in chat_msgs_cols:
        op.add_column('chat_messages', sa.Column('is_voice_note', sa.Boolean(), server_default='false', nullable=True))
    if 'audio_url' not in chat_msgs_cols:
        op.add_column('chat_messages', sa.Column('audio_url', sa.String(), nullable=True))


def downgrade() -> None:
    op.drop_column('chat_messages', 'audio_url')
    op.drop_column('chat_messages', 'is_voice_note')
    op.drop_column('chat_rooms', 'is_secure')
