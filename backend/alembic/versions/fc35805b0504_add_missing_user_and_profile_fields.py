"""add missing user and profile fields

Revision ID: fc35805b0504
Revises: 02e74cc7cf57
Create Date: 2026-07-30 16:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'fc35805b0504'
down_revision: Union[str, Sequence[str], None] = '02e74cc7cf57'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Add missing columns to 'users'
    op.add_column('users', sa.Column('uid', sa.String(), nullable=True))
    op.add_column('users', sa.Column('mid', sa.String(), nullable=True))
    op.add_column('users', sa.Column('username', sa.String(), nullable=True))
    op.add_column('users', sa.Column('display_name', sa.String(), nullable=True))
    op.add_column('users', sa.Column('username_required', sa.Boolean(), server_default='0', nullable=True))
    op.add_column('users', sa.Column('is_banned', sa.Boolean(), server_default='0', nullable=True))
    op.add_column('users', sa.Column('ban_reason', sa.String(), nullable=True))
    op.add_column('users', sa.Column('is_setup_complete', sa.Boolean(), server_default='0', nullable=True))
    op.add_column('users', sa.Column('login_provider', sa.String(), server_default='email', nullable=True))
    op.add_column('users', sa.Column('last_login', sa.DateTime(timezone=True), nullable=True))
    
    op.create_index(op.f('ix_users_uid'), 'users', ['uid'], unique=True)
    op.create_index(op.f('ix_users_mid'), 'users', ['mid'], unique=True)
    op.create_index(op.f('ix_users_username'), 'users', ['username'], unique=True)

    # Add missing columns to 'profiles'
    op.add_column('profiles', sa.Column('city', sa.String(), server_default='Harur', nullable=True))
    op.add_column('profiles', sa.Column('state', sa.String(), server_default='Tamil Nadu', nullable=True))
    op.add_column('profiles', sa.Column('pincode', sa.String(), nullable=True))
    op.add_column('profiles', sa.Column('location_lat', sa.Float(), nullable=True))
    op.add_column('profiles', sa.Column('location_lng', sa.Float(), nullable=True))
    op.add_column('profiles', sa.Column('streak_days', sa.Integer(), server_default='0', nullable=True))
    op.add_column('profiles', sa.Column('reward_points', sa.Integer(), server_default='0', nullable=True))
    op.add_column('profiles', sa.Column('emergency_score', sa.Integer(), server_default='0', nullable=True))
    op.add_column('profiles', sa.Column('news_posted', sa.Integer(), server_default='0', nullable=True))
    op.add_column('profiles', sa.Column('last_active_date', sa.Date(), nullable=True))


def downgrade() -> None:
    # Drop columns from 'profiles'
    op.drop_column('profiles', 'last_active_date')
    op.drop_column('profiles', 'news_posted')
    op.drop_column('profiles', 'emergency_score')
    op.drop_column('profiles', 'reward_points')
    op.drop_column('profiles', 'streak_days')
    op.drop_column('profiles', 'location_lng')
    op.drop_column('profiles', 'location_lat')
    op.drop_column('profiles', 'pincode')
    op.drop_column('profiles', 'state')
    op.drop_column('profiles', 'city')

    # Drop columns from 'users'
    op.drop_index(op.f('ix_users_username'), table_name='users')
    op.drop_index(op.f('ix_users_mid'), table_name='users')
    op.drop_index(op.f('ix_users_uid'), table_name='users')
    
    op.drop_column('users', 'last_login')
    op.drop_column('users', 'login_provider')
    op.drop_column('users', 'is_setup_complete')
    op.drop_column('users', 'ban_reason')
    op.drop_column('users', 'is_banned')
    op.drop_column('users', 'username_required')
    op.drop_column('users', 'display_name')
    op.drop_column('users', 'username')
    op.drop_column('users', 'mid')
    op.drop_column('users', 'uid')
