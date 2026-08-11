# QENBEL UNIFIED PLATFORM — AUDIT REPORT (PHASE 0)
**Date**: August 11, 2026  
**Sources Analyzed**: `D:\QenBel-main` & `D:\harur`  
**Target Architecture**: Single Supabase Project with Isolated Schemas (`qenbel_identity` & `myharur`)

---

## 0.1 — QenBel-main Audit Summary (`D:\QenBel-main`)

- **Framework & Version**:
  - React `^19.2.7`, React Router DOM `^7.18.0`, Vite `^8.1.0`
  - Tailwind CSS `^4.3.2`, Framer Motion `^12.41.0`, Oxlint `^1.69.0`
- **Authentication Implementation**:
  - Currently **No Auth Implementation** in `QenBel-main`. It is a static landing page / digital agency site with marketing sections (Hero, Services, Portfolio, Pricing, Contact, QenShar, CustomQuote).
  - No Supabase client or custom JWT code currently present in `QenBel-main`.
- **Google OAuth / Environment Variables**:
  - None configured in `QenBel-main`.
- **Hardcoded URLs**:
  - None found.
- **End-to-End Status**:
  - Frontend UI builds and runs cleanly as a static web showcase.
  - Auth infrastructure needs to be newly established as `main-qenbel` (FastAPI RS256 Identity Service).

---

## 0.2 — harur Backend & Android Audit Summary (`D:\harur`)

### Backend Framework & Dependencies
- **Framework**: FastAPI (unpinned), SQLAlchemy (unpinned), Python-SocketIO, Celery, Alembic
- **JWT Implementation**:
  - **Algorithm**: `HS256` (Symmetric key, hardcoded fallback `"YOUR_SUPER_SECRET_KEY_FOR_JWT_HERE"`)
  - **TTL**: 7 Days (10,080 minutes)
  - **Key Source**: Environment variable `SECRET_KEY` falling back to default hardcoded string in `config.py`.
- **Socket.IO**:
  - Session Storage: Redis manager present in `main.py` (`socketio.AsyncRedisManager`), but event state handled via basic callbacks.
  - Core Event Names: `connect`, `disconnect`, `join_room`, `send_message`, `typing_start`, `emergency_alert`.
- **API Routers & Prefixes**:
  - Base Prefix: `/api/v1`
  - Routers: `/auth`, `/users`, `/shops`, `/news`, `/emergency`, `/community`, `/marketplace`, `/jobs`, `/admin`, `/access-codes`, `/download`, `/leaderboard`, `/locations`, `/news-sources`, `/notifications`, `/rates`, `/reputation`, `/upload`, `/dashboard`, `/config`.

### IDOR & Auth Flaws Identified
1. **Unverified Google OAuth Endpoint (`/api/v1/auth/google`)**:
   - Accepts arbitrary `{ "email": "...", "first_name": "..." }` in request body with zero ID token validation from Google. Anyone can impersonate any account.
2. **Acceptance of User Identifiers in Request Body**:
   - `user_id` / `owner_id` / `buyer_id` in legacy endpoints allowed client-supplied identity.
   - Fixed requirement for target: Extract `qenbel_id` from JWT `sub`, resolve `mmid` server-side via DB/Redis.
3. **Insecure JWT Issuance**:
   - Single HS256 shared secret allows any service or compromised key holder to issue full admin JWTs. Target requires RS256 with private key restricted strictly to `main-qenbel`.

### Celery & Gemini Integration
- **Celery Tasks**:
  - `crawl_all_sources` (news crawler running as daemon or task)
  - `fetch_gold_rates`, `fetch_harur_weather`
  - Schedule: Periodic background tasks via Redis broker.
- **Gemini AI**:
  - Uses `google-generativeai` package in `ai_router.py`.
  - Model: `gemini-1.5-flash` / `gemini-pro`.
  - Quota Enforcement: Lacks per-user daily hard quota (needs 100 req/day sliding window limit via Redis).

### Android App Audit (`D:\harur\frontend\android`)
- **Package Name**: `com.harurtown.frontend` (Production) / `com.harurtown.alpha` (Alpha test build)
- **Min SDK / Target SDK**: Standard Flutter Gradle managed (`minSdk = 21`, `targetSdk = 34`, `compileSdk = 34`, Java 17).
- **Signing Keystore Status**:
  - **CONFIRMED EXISTS**: `C:\Users\hemap\.android\debug.keystore`
  - **Alias**: `androiddebugkey`
  - **SHA-1 Fingerprint**: `34:2F:B7:FF:63:6C:A9:6F:79:80:0D:18:1E:99:CA:F9:08:04:46:E9`
  - **SHA-256 Fingerprint**: `BA:62:A3:F9:F0:2B:BE:9C:75:41:BE:04:11:BB:6E:19:50:63:63:19:69:58:B1:60:9E:25:16:55:D2:13:66:20`

---

## 0.3 — Supabase Database Table Categorization (68 Tables)

### [IDENTITY] Schema (`qenbel_identity`) — NEW
- `accounts` (Global anchor, `qenbel_id` UUID primary key)
- `oauth_identities` (Google sub to `qenbel_id` mapping)
- `sessions` (Hashed refresh tokens)
- `product_registry` (Registered QenBel products)
- `product_memberships` (Maps `qenbel_id` <-> `product_slug` <-> `product_user_id` / `mmid`)

### [MYHARUR] Schema (`myharur`) — MIGRATED FROM `public`
1. `accounts` (Replaces legacy `public.users`; primary key `mmid`, FK `qenbel_id`)
2. `profiles`
3. `roles`
4. `user_roles`
5. `permissions`
6. `role_permissions`
7. `username_history`
8. `shops`
9. `shop_categories`
10. `shop_offers`
11. `products`
12. `shop_images`
13. `restaurant_rankings`
14. `news`
15. `news_categories`
16. `news_images`
17. `comments`
18. `likes`
19. `duplicate_groups`
20. `news_archive`
21. `news_sources`
22. `crawler_logs`
23. `raw_articles`
24. `emergencies`
25. `emergency_requests`
26. `nearby_help`
27. `volunteers`
28. `government_officials`
29. `marketplace_listings`
30. `job_listings`
31. `job_postings`
32. `listings`
33. `events`
34. `event_tickets`
35. `orders`
36. `tournaments`
37. `tournament_teams`
38. `tournament_fixtures`
39. `polls`
40. `poll_options`
41. `poll_votes`
42. `questions`
43. `answers`
44. `chat_rooms`
45. `chat_messages`
46. `chat_sessions`
47. `knowledge_base`
48. `faqs`
49. `command_history`
50. `intent_logs`
51. `support_tickets`
52. `user_reputation`
53. `leaderboard_snapshots`
54. `states`
55. `districts`
56. `taluks`
57. `towns`
58. `villages`
59. `weather_logs`
60. `donations`
61. `system_settings`
62. `advertisements`
63. `notification_queue`
64. `reports`
65. `download_logs`
66. `deletion_requests`
67. `audit_logs`
68. `access_codes`

---

## 0.4 — Critical Blockers & Action Plan

1. **Android Keystore**: Confirmed existing and accessible (`.android\debug.keystore`).
2. **Database Migration Strategy**: Must execute additive migrations without dropping `public.users` or foreign keys until `myharur.accounts` and `mmid` columns are backfilled.
3. **RS256 Key Pair**: Must be generated (Private key strictly for `main-qenbel`, Public key for `myharur`).
4. **Redis Instance**: Required for rate-limiting, Socket.IO multi-process pub/sub, and MMID resolution caching.

---

**CONFIRMATION GATE STATUS**:
- Android Keystore: **CONFIRMED (EXISTS)**
- OAuth Config Fingerprints: **EXTRACTED**
- Ready for Phase 1 Skeleton Creation upon User Review & Approval.
