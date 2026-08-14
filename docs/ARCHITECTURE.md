# MyHarur system architecture

## 1. High-level shape

```text
Flutter mobile/web client
        |
        | Supabase client with publishable key only
        v
Supabase Auth + Postgres/PostGIS + Storage + Realtime
        ^                         ^
        |                         |
  RLS policies              Edge Functions
                                  |
                         Cron/Vault + allowlisted sources
                                  |
                    news/weather ingestion and privileged actions
```

The client never connects with a database password or service-role key. All privileged writes are either protected by RLS or go through an Edge Function that verifies the caller, role, input, rate limit, and audit requirement.

## 2. Client architecture

Flutter will use a feature-first structure:

```text
lib/
  app/                 routing, theme, dependency setup
  core/                errors, logging, security, config, widgets
  features/
    auth/
    home/
    news/
    weather/
    location/
    emergency/
    marketplace/
    jobs/
    events/
    chat/
    shops/
    support/
    rankings/
    admin/
  shared/              models, repositories, SVG icon set
```

Recommended foundations: `supabase_flutter`, a small immutable state-management layer, `go_router`, `flutter_secure_storage`, `geolocator`, `flutter_map`, `image_picker`, and cached image loading. Exact package versions will be pinned when the Flutter project is scaffolded and verified with the installed SDK.

## 3. Supabase responsibilities

### Auth

- Resident Google sign-in.
- Email/password-backed staff accounts, resolved from a server-managed username alias so staff can enter username + password without storing a second password database.
- MFA required for all super-admin accounts; optional for other users and recommended for every staff account.
- Identity linking after first staff login.
- Short-lived recovery and invitation flows.

### Database

Postgres is the source of truth. PostGIS/geography is used for supported-region checks and nearby emergency response matching. Every user-owned table has an owner/role policy and an audit path.

Core table groups:

- Identity: `profiles`, `roles`, `permissions`, `user_roles`, `admin_ids`, `reserved_usernames`, `blocked_terms`.
- Trust: `audit_events`, `moderation_cases`, `account_actions`, `approval_votes`, `feature_flags`.
- Local information: `news_items`, `news_submissions`, `weather_snapshots`, `custom_reports`, `source_registry`.
- Safety: `emergency_requests`, `emergency_media`, `emergency_responses`, `response_events`, `official_directory`, `service_areas`.
- Community: `marketplace_listings`, `jobs`, `applications`, `events`, `event_registrations`, `temporary_roles`.
- Communication: `chat_rooms`, `chat_members`, `chat_messages`, `support_threads`, `support_messages`, `notifications`.
- Commerce/rankings: `shops`, `products`, `offers`, `donations`, `votes`, `ranking_snapshots`.

### Storage

- Private bucket for emergency evidence and moderation attachments.
- Public or signed-read bucket for approved news/event/shop images.
- Deterministic object paths with user/content UUIDs; no user-supplied path segments.
- MIME/type, size, and image-dimension validation in the function layer.
- Signed URLs with short expiry for private media.

### Edge Functions

Use functions for username resolution, staff onboarding, role changes, super-admin invariants, moderation actions, news/weather ingestion, emergency fan-out, notification dispatch, and ranking snapshots. Functions must be idempotent and write an audit event for privileged actions.

### Scheduling

- News ingestion every two hours.
- Weather refresh on a shorter cached interval, with stale-data indicators.
- Event expiry/archival and notification cleanup.
- Ranking snapshot jobs at a low frequency.

Use Supabase Cron/`pg_cron` + `pg_net` + Vault for scheduled Edge Function calls. Do not place the database password in a cron command, source file, or client build.

## 4. Hosting and free-tier deployment

- Flutter Android build: local/CI artifact for testing.
- Flutter web preview: Render Static Site or equivalent static host, built from GitHub Actions.
- Backend: Supabase project using Auth, Postgres, Storage, Realtime, Edge Functions, Cron, and Vault.
- CI: GitHub Actions for formatting, analyzer, unit/widget tests, and a web build.
- Observability: structured audit events first; optional error tracking later after privacy review.

Render static hosting does not require an always-running application process. A free Render web service may sleep, so it must not own emergency dispatch, scheduled ingestion, or authorization. We will not add artificial keep-alive traffic to bypass a provider's free-tier limits.

## 5. External data policy

News and weather ingestion must use an allowlist of RSS feeds, public APIs, or sources whose terms permit the access pattern. Store source URL, source name, fetched time, content hash, classification reason, and review status. Do not silently republish copyrighted article text; prefer title, short summary, attribution, link, and locally approved image.

