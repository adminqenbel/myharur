from fastapi import APIRouter
from app.api.endpoints import auth, users, shops, news, emergency, rates, config, admin, community

api_router = APIRouter()
api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(shops.router, prefix="/shops", tags=["shops"])
api_router.include_router(news.router, prefix="/news", tags=["news"])
api_router.include_router(emergency.router, prefix="/emergency", tags=["emergency"])
api_router.include_router(rates.router, prefix="/rates", tags=["rates"])
api_router.include_router(config.router, prefix="/config", tags=["config"])
api_router.include_router(admin.router, prefix="/admin", tags=["admin"])
api_router.include_router(community.router, prefix="/community", tags=["community"])
