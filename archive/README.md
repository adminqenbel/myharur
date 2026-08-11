# QENBEL PLATFORM — ARCHIVE README

## Legacy Source Repositories
- `D:\QenBel-main`: Monolithic React/Vite identity showcase landing project.
- `D:\harur`: Monolithic FastAPI backend & Flutter frontend app project.

## Migration Completion Date
- **Date**: August 11, 2026
- **Architecture**: Single Supabase Project with schema isolation (`qenbel_identity` & `myharur`).
- **Services**:
  - `main-qenbel`: RS256 Identity Service & Google OAuth issuer.
  - `myharur`: Core application service with public-key JWT verification, Socket.IO realtime server, and Celery workers.
  - `mobile\myharur_app`: Flutter mobile application.
