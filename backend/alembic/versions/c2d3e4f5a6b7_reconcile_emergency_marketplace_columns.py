"""reconcile emergency and marketplace columns

Revision ID: c2d3e4f5a6b7
Revises: b1c2d3e4f5a6
Create Date: 2026-08-01 13:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.engine.reflection import Inspector


revision: str = "c2d3e4f5a6b7"
down_revision: Union[str, Sequence[str], None] = "b1c2d3e4f5a6"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def _add_missing_columns(table: str, columns: dict[str, sa.Column]) -> None:
    inspector = Inspector.from_engine(op.get_bind())
    existing = {column["name"] for column in inspector.get_columns(table)}
    for name, column in columns.items():
        if name not in existing:
            op.add_column(table, column)


def upgrade() -> None:
    _add_missing_columns(
        "emergencies",
        {
            "description": sa.Column("description", sa.Text(), nullable=True),
            "photo_url": sa.Column("photo_url", sa.String(), nullable=True),
            "video_url": sa.Column("video_url", sa.String(), nullable=True),
            "voice_url": sa.Column("voice_url", sa.String(), nullable=True),
            "escalation_level": sa.Column("escalation_level", sa.String(), server_default="1km", nullable=True),
            "assigned_to": sa.Column("assigned_to", sa.Integer(), nullable=True),
            "eta_minutes": sa.Column("eta_minutes", sa.Integer(), nullable=True),
            "updated_at": sa.Column("updated_at", sa.DateTime(timezone=True), nullable=True),
            "resolved_at": sa.Column("resolved_at", sa.DateTime(timezone=True), nullable=True),
        },
    )
    _add_missing_columns(
        "marketplace_listings",
        {
            "category": sa.Column("category", sa.String(), nullable=True),
            "condition": sa.Column("condition", sa.String(), nullable=True),
            "image_url": sa.Column("image_url", sa.String(), nullable=True),
            "video_url": sa.Column("video_url", sa.String(), nullable=True),
            "contact_phone": sa.Column("contact_phone", sa.String(), nullable=True),
            "location_lat": sa.Column("location_lat", sa.Float(), nullable=True),
            "location_lng": sa.Column("location_lng", sa.Float(), nullable=True),
        },
    )


def downgrade() -> None:
    # This migration repairs production schemas; columns are intentionally retained on downgrade.
    pass
