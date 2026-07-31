"""phase 1 identity

Revision ID: 13f8abc12345
Revises: 02e74cc7cf57
Create Date: 2026-07-31 14:30:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.engine.reflection import Inspector


# revision identifiers, used by Alembic.
revision: str = '13f8abc12345'
down_revision: Union[str, Sequence[str], None] = '8b979b60167e'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    conn = op.get_bind()
    inspector = Inspector.from_engine(conn)
    tables = inspector.get_table_names()

    if 'user_roles' not in tables:
        op.create_table(
            'user_roles',
            sa.Column('user_id', sa.Integer(), nullable=False),
            sa.Column('role_id', sa.Integer(), nullable=False),
            sa.ForeignKeyConstraint(['role_id'], ['roles.id'], ),
            sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
            sa.PrimaryKeyConstraint('user_id', 'role_id')
        )

        # Migrate existing role_id to user_roles
        op.execute("INSERT INTO user_roles (user_id, role_id) SELECT id, role_id FROM users WHERE role_id IS NOT NULL")

    if 'username_history' not in tables:
        op.create_table(
            'username_history',
            sa.Column('id', sa.Integer(), nullable=False),
            sa.Column('user_id', sa.Integer(), nullable=True),
            sa.Column('old_username', sa.String(), nullable=True),
            sa.Column('new_username', sa.String(), nullable=False),
            sa.Column('changed_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
            sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
            sa.PrimaryKeyConstraint('id')
        )
        op.create_index(op.f('ix_username_history_id'), 'username_history', ['id'], unique=False)

def downgrade() -> None:
    op.drop_index(op.f('ix_username_history_id'), table_name='username_history')
    op.drop_table('username_history')
    op.drop_table('user_roles')
