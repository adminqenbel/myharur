# MyHarur security

What is protected, how, what was found and fixed, what is still open, and what to do in the dashboards.
Facts here are checked by tests: `supabase/tests/moderation_test.py` (database, 357 checks), `flutter test` (app),
and the attack probes listed at the end. If you change a rule, change its test.

## 1. Threat model in one paragraph

The app and its Supabase address and public key are in every APK and web bundle, so **nobody can hide the backend**;
the design assumes an attacker knows it and has the public key. Safety therefore comes from what that key can and
cannot do: row-level security on every table, no service key anywhere on a client, privileged actions only through
`SECURITY DEFINER` functions that check role, two-factor level, and rate limits, and secrets that live only in
Supabase (Vault / function secrets), never in the repo or the app.

## 2. Accounts and sign-in

| Rule | Where enforced |
|---|---|
| Google sign-in is primary; e-mail sign-up is refused | trigger on `auth.users` |
| `@username` + password is only a shortcut for Google accounts, through the `username-login` function (the app never learns an account's e-mail; every failure answers the same) | edge function + DB |
| 5 wrong passwords in a row = password sign-in paused 24 h; 3 pauses in a row = off until a super admin recovers it with a written reason. **Only the password path is affected**: usernames are public, so a real ban would let anyone lock out anyone | `record_login_attempt`, `login_locks` |
| Per-IP and per-username throttling, hashed with a server pepper (raw usernames are never stored) | `auth_attempts` |
| Recovery: super admin + two-factor session + reason (10+ chars); signs the person out everywhere; one-time random password, shown once, never stored; the person must choose their own next | `admin_recover_login`, `admin-recover-login` |
| Admins and super admins must use an authenticator app; **the database refuses admin actions without an `aal2` session** (`is_admin()`, `is_superadmin()`, `is_staff()` all check it, so it covers every admin function and admin-only policy). Moderators may enrol but are not forced | `has_aal2()` |
| Session tokens are stored in the Android Keystore-backed store, not plain preferences; backups are off | `secure_session_storage.dart`, manifest |
| Saved accounts for "Switch account" live in the same store, up to 3, removed on sign-out/delete, not used on web | `account_store.dart` |
| Banned accounts see only a suspended page; sessions are revoked on ban | `admin_resolve_user_report` |

## 3. Content, abuse and privacy

- Every post (report or news) is filtered (profanity, dangerous terms, links, phone numbers), rate limited
  (5 reports or 3 news an hour, 30 for staff), and reviewed by a moderator or admin before it appears.
  Three auto-rejections in 24 h put the author on cooldown.
- Photos: private bucket, JPEG/PNG/WebP, 2 MB, 3 per post, 15 uploads an hour. The phone re-encodes every photo,
  which removes EXIF/GPS (**verified on a real phone**: a JPEG carrying camera make/model and GPS came out with no EXIF
  block). Files are only reachable by signed URL, and storage only signs a file for someone who may see the post that uses it.
  Deleted posts lose their images at once and are purged after 30 days.
- Report and block go through the post, so a resident never learns who wrote it. Three different aged accounts reporting
  the same author within 7 days auto-restrict them until an admin decides; staff are never auto-restricted.
  Brand-new accounts do not count as reporters. Admin decisions are audited.
- The audit log is append-only. Account deletion still works (rows are anonymised, not removed).
- Support AI: signed-in users only, 10 questions a day each and a daily cap for the whole app; e-mail addresses and long
  numbers are removed before anything reaches the model; the prompt is topic-locked and treats user text as data.
- Notifications: one report summary a day at most, event alerts at most twice a week, none between 22:00 and 07:00 India
  time. The caps are enforced in SQL, not in the sender. Push tokens are unreadable through the API.
- Known and accepted: the post row exposes the author's opaque user id to signed-in residents (not a name or e-mail;
  used by the app to show "delete" on your own posts). It does allow linking one author's posts together.

## 4. Web and app hardening

- Android: `allowBackup=false` + data-extraction rules, R8 shrink/minify, no cleartext traffic (network security config),
  release logging off (a `secureLog` wrapper prints nothing in release and never prints tokens).
- All outbound links go through one allow-list (`safeLaunch`: https, tel, mailto, geo; no credentials in URLs). The database
  also requires stored links to be `https://`.
- Web (nginx on Render): CSP, HSTS, `X-Content-Type-Options`, `Referrer-Policy`, `Permissions-Policy`, frame protection.
- Errors reported by the app are redacted (no tokens, e-mails or long numbers), rate limited, and readable by super admins only.

## 5. Findings from the audit and their fixes

| Finding | Severity | Fix |
|---|---|---|
| Anyone could publish "official" alerts (open RLS, client-chosen source/status) | Critical | RLS closed; trigger sets author, source, status; moderation only through `moderate_alert()` |
| Profile PII (name, phone, blood group, e-mail) world-readable | Critical | RLS: own row, or admins at `aal2` |
| Legacy `gemini-proxy` reachable with any JWT, holding a Gemini key | High | deleted; replaced by `support-ai` with user checks, quotas and scrubbing |
| Legacy `auth-staff-login` never verified the password | Critical | deleted |
| Four other unused legacy edge functions | Medium | deleted (archived under `supabase/archive/`) |
| Audit log could be edited or deleted | Medium | append-only trigger |
| Session in plain SharedPreferences, backups allowed | High | Keystore-backed storage; backups off |
| Profile guard referenced a dropped column, leaving trust columns writable | High | redefined and re-tested |
| 28 `debugPrint` calls printed roles/profile state in release | Low | `secureLog` |
| Token refresh triggered a profile reload which triggered another refresh (about 4 requests a second) | Medium | reload only on real sign-ins |
| Admin functions honoured a stolen Google session | High | `aal2` required in the role helpers |
| New `alerts` policy would have hidden the public feed from anonymous callers | Found in test | policy helper is `SECURITY DEFINER` |

## 6. Open items (please read)

1. **Rotate the Google OAuth client secret.** It was pasted into a chat during setup. Google Cloud console > Credentials >
   the Web client > add a new secret, put it in Supabase Auth > Google, then disable the old one.
2. **Supabase dashboard settings** (cannot be set from the CLI):
   - Authentication > Providers > Email: keep *Confirm e-mail* on; sign-ups are also refused by a trigger.
   - Authentication > Policies: minimum password length 10; enable leaked-password protection if your plan allows.
   - Authentication > Sessions: JWT expiry 3600 s, refresh-token rotation on, reuse interval 10 s.
   - Authentication > URL configuration: redirect allow-list must contain only `com.myharur.app://login-callback`
     and your Render site URL.
   - Authentication > Multi-factor: TOTP enabled (it is; two-factor works).
   - Add a second super admin, so a lost authenticator can be reset.
3. **Release builds** must use `--obfuscate --split-debug-info` (see `docs/RELEASE.md`) and a real signing keystore.
4. **The "Security by QenShar" wording** is a marketing claim inside the app: it must stay true, and you should confirm the
   sentence before a Play release.
5. **Open-source map tiles and geocoding** (OpenStreetMap) are fine at launch traffic; move to a hosted provider at scale.
6. **Play Integrity attestation** and a Cloudflare proxy on your own domain (so the raw `supabase.co` address is not in the
   app) are the next hardening steps. They need a domain and Play Console access.
7. **Tamil text** needs a native-speaker review before release.

## 7. How this was verified

- Database: 357 automated checks, run against a throwaway Postgres 16 with every migration applied twice in a row.
- App: widget and unit tests (`flutter test`), plus an on-device check that photo metadata is stripped.
- Production probes with only the public key (all refused): forged publish, reading other tables (`user_reports`,
  `user_blocks`, `login_locks`, `security_events`, tokens), calling admin functions, calling `support-ai` without a
  real session, calling the cron-secret functions without the secret, and brute-forcing `username-login`
  (throttled after 5 tries, unknown usernames never locked).
