from fastapi import APIRouter
from app.api.endpoints import auth, users, shops, news, emergency, rates, config, admin, community, upload, locations, news_sources, leaderboard, dashboard

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
api_router.include_router(upload.router, prefix="/upload", tags=["upload"])
api_router.include_router(locations.router, prefix="/locations", tags=["locations"])
api_router.include_router(news_sources.router, prefix="/news-sources", tags=["news_sources"])
api_router.include_router(leaderboard.router, prefix="/leaderboard", tags=["leaderboard"])
api_router.include_router(dashboard.router, prefix="/dashboard", tags=["dashboard"])
