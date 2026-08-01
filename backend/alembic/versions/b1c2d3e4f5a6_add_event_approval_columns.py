"""add missing event approval columns

Revision ID: b1c2d3e4f5a6
Revises: afaf0725e0c3
Create Date: 2026-08-01 12:30:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.engine.reflection import Inspector


revision: str = "b1c2d3e4f5a6"
down_revision: Union[str, Sequence[str], None] = "afaf0725e0c3"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Bring older deployed event tables in line with the Event model."""
    inspector = Inspector.from_engine(op.get_bind())
    columns = {column["name"] for column in inspector.get_columns("events")}

    if "status" not in columns:
        op.add_column(
            "events",
            sa.Column("status", sa.String(), server_default="pending", nullable=True),
        )
        op.create_index("ix_events_status", "events", ["status"], unique=False)
    if "payment_link" not in columns:
        op.add_column("events", sa.Column("payment_link", sa.String(), nullable=True))
    if "chat_room_id" not in columns:
        op.add_column("events", sa.Column("chat_room_id", sa.Integer(), nullable=True))
        op.create_foreign_key(
            "fk_events_chat_room_id_chat_rooms",
            "events",
            "chat_rooms",
            ["chat_room_id"],
            ["id"],
        )


def downgrade() -> None:
    op.drop_constraint("fk_events_chat_room_id_chat_rooms", "events", type_="foreignkey")
    op.drop_column("events", "chat_room_id")
    op.drop_column("events", "payment_link")
    op.drop_index("ix_events_status", table_name="events")
    op.drop_column("events", "status")
