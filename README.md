# MyHarur

Civic app for **Harur and Dharmapuri (Tamil Nadu)**, a QenBel product. Community alerts, local news,
weather and emergency helplines, in English and Tamil.

**Status (Sep 2026):** v1 feature-complete on the app and backend; preparing for Google Play.
See `docs/RELEASE.md` for the release checklist and what is still open.

## What is in the app

| Tab | What it does |
|---|---|
| **Home** | Approved alerts (road, electricity, water, government), weather card, report button. Staff see a "waiting for review" banner. |
| **News** | Local headlines (traffic, weather, civic, farming) from a crawler that runs every 30 minutes. Links out to the publisher. |
| **Weather** | Blue-to-red hero, hourly strip, 7-day forecast, details. Harur and Dharmapuri. Data: Open-Meteo. |
| **Help** | National and state helplines, tap to call. |
| **Account** | Google profile (name, photo), profile details, language (English / தமிழ்), staff tools, staff password, delete account. |

## How an alert becomes public

```
resident or staff submits a report
        |
        v
 Postgres BEFORE INSERT trigger (cannot be bypassed by the client)
   forces status=pending, source and author          5 reports/hour for residents
   blocked words        -> auto-rejected              dangerous words, links, phone numbers -> flagged
        |
        v
 Review queue (Account > Staff tools > Review queue)
   any moderator, admin or super admin approves (live 7 days) or rejects with a reason
        |
        v
 Public feed shows only approved, unexpired alerts
```

## Roles and sign-in

Roles live in `user_roles`: `resident` (default), `moderator`, `govt_official`, `admin`, `superadmin`.

- **Residents** sign in with **Google**. Email sign-up is disabled in the database (trigger `block_email_signup`).
- **Staff** also sign in with Google first, then add a password under Account > Security > Staff password.
  After that the same account works with either Google or email + password.
- **Who can change roles** (enforced in `admin_set_role`): admins grant/revoke moderator and government official;
  only super admins grant/revoke admin and super admin. Maximum 3 super admins, and the last one cannot be removed.
- **Admin panel** (Account > Staff tools): overview numbers, users and roles, word filters (super admin only).

## Stack and code map

| Layer | Tech | Where |
|---|---|---|
| App (Android + web) | Flutter 3.44 / Dart 3.12, Inter font, English + Tamil (gen-l10n) | `lib/` |
| Backend | Supabase (Postgres + RLS + Auth + Edge Functions + pg_cron) | `supabase/` |
| Web hosting | Render free tier (Docker + nginx) | `Dockerfile`, `render.yaml`, `nginx.conf` |
| CI | GitHub Actions: APK (+ AAB when signing secrets exist) | `.github/workflows/ci.yml` |

- `lib/main.dart`: entry, splash, auth routing, 5-tab shell
- `lib/features/splash/splash_gate.dart`: opening animation (logo lifts, wordmark rises, cross-fades into the app)
- `lib/core/widgets/ui.dart`: the UI kit (large-title header, grouped lists, segmented control, tab bar, cards)
- `lib/core/theme/app_theme.dart`: colours, type scale, theme
- `lib/core/services/`: `auth`, `alerts`, `news`, `weather`, `admin`, `supabase_config`
- `lib/features/`: `home`, `news`, `weather`, `help`, `account`, `admin`, `moderation`, `alerts` (submit), `auth`, `onboarding`, `common`
- `lib/l10n/app_en.arb`, `app_ta.arb`: all UI strings. Add a string to both files, then run `flutter gen-l10n`.
- `supabase/migrations/`: baseline, moderation pipeline, function privileges, super admin + news, crawler schedule
- `supabase/functions/news-crawler/`: the news crawler (see `docs/NEWS.md`). Other functions in that folder are legacy and unused.
- `supabase/tests/moderation_test.py`: SQL/RLS test suite on a throwaway Postgres (108 checks)
- `design/logo-master.png`: the master logo. `python tools/generate_brand_assets.py` regenerates every derived asset:
  launcher icons (adaptive, legacy, Android 13 themed), native splash art, web icons, Play Store icon, in-app logo
- `supabase/archive/`, `docs/archive/`: the earlier "full digital town" design, for phase B

## Run and test

```bash
export PATH="/d/flutter/bin:$PATH"     # Flutter lives at D:\flutter
flutter pub get
flutter gen-l10n                        # after editing lib/l10n/*.arb
flutter analyze && flutter test
flutter run -d <device-id>
```

SQL tests (needs Docker):

```bash
docker run -d --name mh-pg -e POSTGRES_PASSWORD=pw -p 55432:5432 postgres:16
pip install psycopg2-binary && python supabase/tests/moderation_test.py
docker rm -f mh-pg
```

Backend changes: add a file under `supabase/migrations/`, test it with the SQL suite, then
`npx supabase db push --linked` (workflow in `docs/RELEASE.md`).

## Things to know

- Client config is public by design (URL and publishable key are built in; override with
  `--dart-define=SUPABASE_URL=...` and `--dart-define=SUPABASE_PUBLISHABLE_KEY=...`).
  Never put a `service_role` key or DB password in this repo.
- Word lists are starter lists. Super admins curate them in the app (Admin panel > Word filters), no release needed.
  Tamil and Tanglish words still need adding.
- Wards are an optional detail (Account, or when reporting). They are not part of onboarding.
- Helplines in `help_page.dart` are national and state numbers only. Add verified local numbers there.
- Weather uses the free Open-Meteo API (attribution shown in the app). Its free tier is for non-commercial use;
  switch to their paid plan or your own cache before scaling.
