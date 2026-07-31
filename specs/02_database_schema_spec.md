# Database Schema Specification
## Overview
The application utilizes an advanced relational schema built in PostgreSQL via SQLAlchemy and Alembic migrations.

## Core Models
### User Engine (`users`)
Abstracts sensitive authentication logic from public profiles.
- `id` (PK, Integer)
- `uid` (UUID, internal identifier)
- `mid` (String, MyHarur Member ID for public addressing, e.g., 'SYS000001')
- `username` (String, unique)
- `hashed_password` (String, Argon2/Bcrypt secured)
- `role_id` (FK to roles)

### Role System (`roles` & `user_roles`)
Supports dynamic multi-role assignment allowing users to be Citizen, Volunteer, and Shop Admin simultaneously.

### Profiles (`profiles`)
Public-facing user data and metrics.
- `user_id` (FK to users)
- `first_name`, `last_name`, `bio`, `avatar_url`
- `streak_days`, `reward_points`, `volunteer_hours` (Gamification Metrics)
- `emergency_score`, `news_posted` (Reputation Metrics)
- `location_lat`, `location_lng`

### News Intelligence (`news`)
- `id` (PK)
- `author_id` (FK to users)
- `title`, `description`, `image_url`
- `is_approved` (Boolean for moderation queue)
- `verified_by` (FK to admin user)

### Community & Chat (`chat_rooms`, `chat_messages`)
- `chat_rooms`: Stores DM or Group instances (`is_secure` flag available).
- `chat_messages`: Stores real-time messages.
  - `sender_id` (FK to users)
  - `content` (Text)
  - `is_voice_note` (Boolean)
  - `audio_url` (String)

## Resilience Strategy
To combat "Multiple Alembic Heads" or locked migrations in production, `app/main.py` utilizes a fallback `startup_event` containing raw SQL (`ALTER TABLE ... ADD COLUMN IF NOT EXISTS`) to dynamically inject expected schema columns without relying solely on Alembic.
