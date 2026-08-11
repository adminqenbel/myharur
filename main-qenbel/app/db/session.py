from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import declarative_base
from app.config import get_settings

settings = get_settings()

# Convert standard postgresql:// to postgresql+asyncpg:// if needed
db_url = settings.supabase_url
if "postgresql://" in db_url and not "asyncpg" in db_url:
    db_url = db_url.replace("postgresql://", "postgresql+asyncpg://")

engine = create_async_engine(
    db_url if db_url.startswith("postgresql+asyncpg") else "sqlite+aiosqlite:///./identity.db",
    echo=not settings.is_production,
    future=True
)

AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False
)

Base = declarative_base()

async def get_db():
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()
