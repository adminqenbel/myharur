# Backend API & Systems Specification

## REST Interface
- **Framework**: FastAPI (Pydantic V2 schemas).
- **Core Endpoints**:
  - `/auth/login`: Issues HS256 JWT Access Tokens (password via OAuth2PasswordRequestForm or Google OAuth).
  - `/news/`: Fetches RSS aggregated local news. Optimized with limited outer joins (preventing N+1 queries).
  - `/community/`, `/market/`, `/events/`: Core platform resources mapped to standard CRUD patterns.

## Background Automation
- **RSS Crawler**: A threaded process (`bg_fetch_news`) operating behind the scenes scraping Google News RSS feeds for "Harur" and "Dharmapuri". Stores non-duplicate findings automatically to the `news` table.
- **Queue System**: Celery initialized with Redis broker for heavy asynchronous tasks (e.g., intensive AI operations, large-scale notifications).

## Real-Time Engine (Socket.IO)
- **ASGI Adapter**: Mounted via `socketio.ASGIApp` onto the core FastAPI loop.
- **Redis Multi-Node**: Utilizes `AsyncRedisManager(redis_url)` for Pub/Sub horizontal scaling. Graceful degradation: if `REDIS_URL` is omitted or offline, falls back seamlessly to local in-memory dictionaries and UUIDs.
- **Intelligent Routing**: 
  - Chat engine listens for `@system`, `@support`, or `@news`. 
  - Offloads parsing to the `IntelligentRouter` pipeline.
  - Asynchronously replies back in the exact Socket.IO room with conversational or command-based execution results.
