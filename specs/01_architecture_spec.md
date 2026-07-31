# Architecture Specification
## Platform Overview
MyHarur V4.0 is an enterprise hyperlocal super-app platform connecting citizens, businesses, local government, and reporters in a unified digital ecosystem.

## High-Level Architecture
The platform is built on a decoupled Client-Server architecture:
1. **Frontend**: Flutter-based mobile application (Android/iOS)
2. **Backend**: FastAPI (Python) REST & WebSocket API
3. **Database**: PostgreSQL (hosted on Supabase) accessed via SQLAlchemy ORM
4. **Caching & Pub/Sub**: Redis for session state, rate-limiting, background queues (Celery), and Socket.IO real-time event broadcasting

## Deployment Topology
- **Production Server**: Render/Ubuntu VPS hosting Dockerized Python containers
- **Database Layer**: Remote Supabase PostgreSQL instance
- **CI/CD**: GitHub Actions / Render auto-deploy bound to the `main` branch.

## File System Structure
- `/backend`: FastAPI Python application
  - `/alembic/versions`: Database migration scripts for linear schema updates
  - `/app/api`: FastAPI route handlers (REST endpoints)
  - `/app/core`: System configs, JWT security, Redis adapters, Celery init
  - `/app/models`: SQLAlchemy table definitions
  - `/app/crud`: Database access and business logic wrappers
  - `/app/main.py`: ASGI entry point and FastAPI app instantiation
- `/frontend`: Flutter Dart application
  - `/lib/screens`: UI Views and layout definitions
  - `/lib/providers`: Riverpod state management logic (e.g., AuthNotifier)
  - `/lib/api_client.dart`: Centralized Dio client with Auth Interceptors
  - `/lib/theme.dart`: Centralized typography and color tokens
  - `/lib/main.dart`: Entry point containing GoRouter configuration
