# MyHarur delivery phases

## Phase 0 — architecture and guardrails (current)

Deliverables:

- Product scope, architecture, security model, UI direction, and deployment plan.
- Secret-safe repository baseline.
- Decision log for ambiguous requirements.

Exit criteria: no credentials committed; the first vertical slice and its trust boundaries are agreed.

## Phase 1 — secure shell and visual foundation

Build:

- Flutter project, routing, design tokens, SVG icon system, responsive layout, and Apple-like home shell.
- Supabase initialization with environment configuration.
- Auth screens: Google resident sign-in; staff username/password onboarding flow.
- Profile, UUID/MMID/username display, role-aware navigation, MFA enrollment screen.
- Home with mock-backed news, weather, location picker, map preview, and emergency entry point.

Verification:

- `flutter analyze`, formatting, widget tests, Android debug build, and Render web preview.
- No service-role key or DB password appears in the app bundle, repository, or CI logs.

## Phase 2 — trusted local information and emergency MVP

Build:

- News submission, approval, publish, source attribution, image upload, and two-hour ingestion.
- Weather snapshots and admin/user report workflow.
- Supported-region geofence and manual location selection.
- Emergency request with media, timeline, official response, nearby-help fan-out, and audit trail.
- Admin moderation queue.

Verification:

- RLS tests for every ownership and role path.
- Emergency test matrix for 1/5/10 km escalation, duplicate taps, offline retry, expired case, and unauthorized viewers.

## Phase 3 — community participation

Build marketplace, jobs, events/tournaments, registration, event head, expiry/archival, and basic support escalation.

Verification: abuse limits, report/appeal flows, expiry jobs, registration privacy, and content moderation.

## Phase 4 — communication and commerce

Build public/temporary chat, shop admin with two-shop limit, products/offers/stock, notifications, and government publishing area.

Verification: realtime authorization, moderator actions, media access, shop ownership, role inheritance, and audit review.

## Phase 5 — rankings, donations, and production hardening

Build ranking snapshots, donation portal, anti-vote abuse, payment reconciliation, retention controls, backups, incident playbooks, and release monitoring.

Verification: load tests against free-tier quotas, privacy review, threat model review, restore drill, and staged rollout.

## Build order inside each phase

`schema/RLS -> server function -> repository -> UI state -> screen -> tests -> preview deploy`

That order keeps the client from becoming the source of truth for permissions or workflow status.

