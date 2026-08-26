# System Build & Execution Log

**Assistant / Model:** Gemini 3.7 Flash (High) — Antigravity AI Coding Assistant (Google DeepMind)
**Date & Time:** 2026-08-26 00:08:30 IST
**Status:** COMPLETE — SCHEMAS EXECUTED & VERIFIED ON LIVE SUPABASE DATABASES

---

## 1. Live Database Migrations Executed

### A. QenBel Identity Database (`db.dtkclyrypucngoenwncj` at `ap-south-1`)
- **Host:** `aws-0-ap-south-1.pooler.supabase.com:5432`
- **Schema File:** `D:\qenbel-administration\sql\01_qenbel_identity_schema.sql`
- **Status:** **`✓ EXECUTED & VERIFIED`**
- **Live Tables:**
  - `qenbel_users` (User identity, avatar, global roles `admin`/`superadmin`)
  - `applications` (Registered products: `myharur`, `qenshar`)
  - `application_users` (Cross-app user mapping)
  - `admin_audit_log` (Immutable security audit log)
  - `system_events` (Health & incident tracking)
  - `announcements` (Cross-product broadcasts)

### B. MyHarur Product Database (`db.qpuvhhvzygdbvlichbqs` at `ap-south-1`)
- **Host:** `aws-0-ap-south-1.pooler.supabase.com:5432`
- **Schema File:** `D:\myharur\supabase_schema_v2.sql`
- **Status:** **`✓ EXECUTED & VERIFIED`**
- **Live Tables:**
  - `wards` (18 Harur wards seeded)
  - `alerts` (Primary v1 launch surface: Road, Electricity, Water, Govt)
  - `user_roles` (Additive multi-role join table: `resident`, `govt_official`, `admin`)
  - `moderation_queue` (24h auto-expiring community moderation)
  - `module_flags` (`jobs`, `events`, `tournaments`, `chat` flag-gated off by default)
  - `profiles` (Product profiles with MMID and onboarding state)
  - `profanity_wordlist` (Central profanity moderation)
  - `crud_audit_logs` (Product-level audit log)
  - `jobs`, `events`, `chat_messages` (Preserved tables for deferred modules)

---

## 2. Product Matrix & Client IDs
- **QenBel Admin Web Client ID:** `976428818123-967r95km89gmvicai4et4l6csnt6mq8v.apps.googleusercontent.com`
- **MyHarur Android Client ID:** `976428818123-tr1tgub2a690vh7g88s2icpq19smmuvv.apps.googleusercontent.com`

---

## 3. Production Verification
- **QenBel Admin Build:** `npm run build` (Next.js 16+ Turbopack) — **`✓ Exit Code 0`**
- **MyHarur Tests:** `flutter test` — **`✓ Exit Code 0`** (All 4 unit test suites passed)
- **MyHarur Code Analysis:** `flutter analyze` — **`✓ Exit Code 0`** (0 errors)
- **Live Database Seed Check:** Both Supabase instances verified with active tables and seed data.