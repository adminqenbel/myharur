"""Add V4 Phase 2 tables and indexes

Revision ID: afaf0725e0c3
Revises: 7g8h9i0j1k2l
Create Date: 2026-07-31 20:23:00.825501

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'afaf0725e0c3'
down_revision: Union[str, Sequence[str], None] = '7g8h9i0j1k2l'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Add index to chat_messages
    op.create_index(op.f('ix_chat_messages_room_id'), 'chat_messages', ['room_id'], unique=False)
    op.create_index(op.f('ix_chat_messages_sender_id'), 'chat_messages', ['sender_id'], unique=False)
    op.create_index(op.f('ix_chat_messages_created_at'), 'chat_messages', ['created_at'], unique=False)

    # 1. PERMISSIONS
    op.create_table('permissions',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('name', sa.String(), nullable=True),
        sa.Column('description', sa.String(), nullable=True),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_permissions_id'), 'permissions', ['id'], unique=False)
    op.create_index(op.f('ix_permissions_name'), 'permissions', ['name'], unique=True)

    op.create_table('role_permissions',
        sa.Column('role_id', sa.Integer(), nullable=False),
        sa.Column('permission_id', sa.Integer(), nullable=False),
        sa.ForeignKeyConstraint(['permission_id'], ['permissions.id'], ),
        sa.ForeignKeyConstraint(['role_id'], ['roles.id'], ),
        sa.PrimaryKeyConstraint('role_id', 'permission_id')
    )

    # 2. GOVERNMENT OFFICIALS
    op.create_table('government_officials',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=True),
        sa.Column('department', sa.String(), nullable=False),
        sa.Column('designation', sa.String(), nullable=False),
        sa.Column('office_address', sa.Text(), nullable=True),
        sa.Column('office_phone', sa.String(), nullable=True),
        sa.Column('is_verified', sa.Boolean(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('user_id')
    )
    op.create_index(op.f('ix_government_officials_department'), 'government_officials', ['department'], unique=False)
    op.create_index(op.f('ix_government_officials_id'), 'government_officials', ['id'], unique=False)

    # 3. VOLUNTEERS
    op.create_table('volunteers',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=True),
        sa.Column('skills', sa.String(), nullable=True),
        sa.Column('availability', sa.String(), nullable=True),
        sa.Column('total_hours_logged', sa.Float(), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('user_id')
    )
    op.create_index(op.f('ix_volunteers_id'), 'volunteers', ['id'], unique=False)

    # 4. ORDERS
    op.create_table('orders',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('buyer_id', sa.Integer(), nullable=True),
        sa.Column('shop_id', sa.Integer(), nullable=True),
        sa.Column('total_amount', sa.Float(), nullable=False),
        sa.Column('status', sa.String(), nullable=True),
        sa.Column('shipping_address', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(['buyer_id'], ['users.id'], ),
        sa.ForeignKeyConstraint(['shop_id'], ['shops.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_orders_created_at'), 'orders', ['created_at'], unique=False)
    op.create_index(op.f('ix_orders_id'), 'orders', ['id'], unique=False)
    op.create_index(op.f('ix_orders_status'), 'orders', ['status'], unique=False)

    # 5. TOURNAMENTS
    op.create_table('tournaments',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('organizer_id', sa.Integer(), nullable=True),
        sa.Column('sport_type', sa.String(), nullable=False),
        sa.Column('name', sa.String(), nullable=False),
        sa.Column('start_date', sa.DateTime(timezone=True), nullable=True),
        sa.Column('end_date', sa.DateTime(timezone=True), nullable=True),
        sa.Column('location', sa.String(), nullable=True),
        sa.Column('prize_pool', sa.String(), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.ForeignKeyConstraint(['organizer_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_tournaments_id'), 'tournaments', ['id'], unique=False)
    op.create_index(op.f('ix_tournaments_sport_type'), 'tournaments', ['sport_type'], unique=False)

    # 6. LEADERBOARD
    op.create_table('leaderboard_snapshots',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('category', sa.String(), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=True),
        sa.Column('rank', sa.Integer(), nullable=False),
        sa.Column('score', sa.Float(), nullable=False),
        sa.Column('snapshot_date', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_leaderboard_snapshots_category'), 'leaderboard_snapshots', ['category'], unique=False)
    op.create_index(op.f('ix_leaderboard_snapshots_id'), 'leaderboard_snapshots', ['id'], unique=False)
    op.create_index(op.f('ix_leaderboard_snapshots_snapshot_date'), 'leaderboard_snapshots', ['snapshot_date'], unique=False)

    # 7. WEATHER
    op.create_table('weather_logs',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('temperature', sa.Float(), nullable=False),
        sa.Column('condition', sa.String(), nullable=False),
        sa.Column('humidity', sa.Float(), nullable=True),
        sa.Column('recorded_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_weather_logs_id'), 'weather_logs', ['id'], unique=False)
    op.create_index(op.f('ix_weather_logs_recorded_at'), 'weather_logs', ['recorded_at'], unique=False)

    # 8. DONATION
    op.create_table('donations',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('donor_id', sa.Integer(), nullable=True),
        sa.Column('cause', sa.String(), nullable=False),
        sa.Column('amount', sa.Float(), nullable=False),
        sa.Column('transaction_id', sa.String(), nullable=True),
        sa.Column('status', sa.String(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.ForeignKeyConstraint(['donor_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_donations_id'), 'donations', ['id'], unique=False)

    # 9. RESTAURANT RANKING
    op.create_table('restaurant_rankings',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('shop_id', sa.Integer(), nullable=True),
        sa.Column('average_rating', sa.Float(), nullable=True),
        sa.Column('total_reviews', sa.Integer(), nullable=True),
        sa.Column('rank_score', sa.Float(), nullable=True),
        sa.Column('last_updated', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.ForeignKeyConstraint(['shop_id'], ['shops.id'], ),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('shop_id')
    )
    op.create_index(op.f('ix_restaurant_rankings_id'), 'restaurant_rankings', ['id'], unique=False)
    op.create_index(op.f('ix_restaurant_rankings_rank_score'), 'restaurant_rankings', ['rank_score'], unique=False)


def downgrade() -> None:
    op.drop_index(op.f('ix_restaurant_rankings_rank_score'), table_name='restaurant_rankings')
    op.drop_index(op.f('ix_restaurant_rankings_id'), table_name='restaurant_rankings')
    op.drop_table('restaurant_rankings')
    op.drop_index(op.f('ix_donations_id'), table_name='donations')
    op.drop_table('donations')
    op.drop_index(op.f('ix_weather_logs_recorded_at'), table_name='weather_logs')
    op.drop_index(op.f('ix_weather_logs_id'), table_name='weather_logs')
    op.drop_table('weather_logs')
    op.drop_index(op.f('ix_leaderboard_snapshots_snapshot_date'), table_name='leaderboard_snapshots')
    op.drop_index(op.f('ix_leaderboard_snapshots_id'), table_name='leaderboard_snapshots')
    op.drop_index(op.f('ix_leaderboard_snapshots_category'), table_name='leaderboard_snapshots')
    op.drop_table('leaderboard_snapshots')
    op.drop_index(op.f('ix_tournaments_sport_type'), table_name='tournaments')
    op.drop_index(op.f('ix_tournaments_id'), table_name='tournaments')
    op.drop_table('tournaments')
    op.drop_index(op.f('ix_orders_status'), table_name='orders')
    op.drop_index(op.f('ix_orders_id'), table_name='orders')
    op.drop_index(op.f('ix_orders_created_at'), table_name='orders')
    op.drop_table('orders')
    op.drop_index(op.f('ix_volunteers_id'), table_name='volunteers')
    op.drop_table('volunteers')
    op.drop_index(op.f('ix_government_officials_id'), table_name='government_officials')
    op.drop_index(op.f('ix_government_officials_department'), table_name='government_officials')
    op.drop_table('government_officials')
    op.drop_table('role_permissions')
    op.drop_index(op.f('ix_permissions_name'), table_name='permissions')
    op.drop_index(op.f('ix_permissions_id'), table_name='permissions')
    op.drop_table('permissions')
    op.drop_index(op.f('ix_chat_messages_created_at'), table_name='chat_messages')
    op.drop_index(op.f('ix_chat_messages_sender_id'), table_name='chat_messages')
    op.drop_index(op.f('ix_chat_messages_room_id'), table_name='chat_messages')
