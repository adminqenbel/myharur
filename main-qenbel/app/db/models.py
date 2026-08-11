import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Boolean, DateTime, ForeignKey, Text, JSON
from sqlalchemy.dialects.postgresql import UUID, INET, JSONB
from sqlalchemy.sql import func
from app.db.session import Base

def gen_uuid():
    return uuid.uuid4()

class Account(Base):
    __tablename__ = "accounts"
    __table_args__ = {"schema": "qenbel_identity"}

    qenbel_id = Column(UUID(as_uuid=True), primary_key=True, default=gen_uuid)
    email_normalized = Column(String, unique=True, nullable=False, index=True)
    display_name = Column(String, nullable=True)
    avatar_url = Column(String, nullable=True)
    status = Column(String, nullable=False, default="active")
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)


class OAuthIdentity(Base):
    __tablename__ = "oauth_identities"
    __table_args__ = {"schema": "qenbel_identity"}

    id = Column(UUID(as_uuid=True), primary_key=True, default=gen_uuid)
    qenbel_id = Column(UUID(as_uuid=True), ForeignKey("qenbel_identity.accounts.qenbel_id", ondelete="CASCADE"), nullable=False, index=True)
    provider = Column(String, nullable=False)
    provider_user_id = Column(String, nullable=False)
    provider_email = Column(String, nullable=True)
    linked_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)


class Session(Base):
    __tablename__ = "sessions"
    __table_args__ = {"schema": "qenbel_identity"}

    session_id = Column(UUID(as_uuid=True), primary_key=True, default=gen_uuid)
    qenbel_id = Column(UUID(as_uuid=True), ForeignKey("qenbel_identity.accounts.qenbel_id", ondelete="CASCADE"), nullable=False, index=True)
    refresh_token_hash = Column(String, unique=True, nullable=False)
    issued_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=False, index=True)
    revoked = Column(Boolean, default=False, nullable=False)
    user_agent = Column(Text, nullable=True)
    ip_address = Column(String, nullable=True)


class ProductRegistry(Base):
    __tablename__ = "product_registry"
    __table_args__ = {"schema": "qenbel_identity"}

    product_id = Column(UUID(as_uuid=True), primary_key=True, default=gen_uuid)
    product_slug = Column(String, unique=True, nullable=False)
    product_name = Column(String, nullable=False)
    service_url = Column(String, nullable=False)
    provisioning_config = Column(JSON, nullable=False, default={})
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)


class ProductMembership(Base):
    __tablename__ = "product_memberships"
    __table_args__ = {"schema": "qenbel_identity"}

    membership_id = Column(UUID(as_uuid=True), primary_key=True, default=gen_uuid)
    qenbel_id = Column(UUID(as_uuid=True), ForeignKey("qenbel_identity.accounts.qenbel_id", ondelete="CASCADE"), nullable=False, index=True)
    product_slug = Column(String, ForeignKey("qenbel_identity.product_registry.product_slug"), nullable=False)
    product_user_id = Column(String, nullable=False)
    provisioned_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
