from app.db.session import Base
from app.models.user import User, Role, Profile
from app.models.shop import Shop, ShopCategory, ShopOffer, Product, ShopImage
from app.models.news import News, NewsCategory, NewsImage, Comment, Like, DuplicateGroup, NewsArchive
from app.models.emergency import EmergencyRequest, NearbyHelp
from app.models.system import SystemSetting, Advertisement, Report, NotificationQueue
from app.models.community import (
    Listing, JobPosting, Event,
    Poll, PollOption, PollVote,
    Question, Answer,
    ChatRoom, ChatMessage
)
from app.models.location import State, District, Taluk, Town, Village
from app.models.ingestion import NewsSource, CrawlerLog, RawArticle
from app.models.ai import KnowledgeBase, FAQ, ChatSession, CommandHistory, IntentLog
