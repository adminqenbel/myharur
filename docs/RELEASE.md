# Release & Google Play checklist

## 0. Versioning policy

`pubspec.yaml`'s `version:` field is `MAJOR.PRODUCTION.0+BUILD`:

- **MAJOR** — bumped only for a major rework (a rewrite-scale change to the app, like the
  2026-09 security-first rebuild). Expected to change rarely.
- **PRODUCTION** (the middle number) — bumped for each release cycle that ships a meaningful,
  production-ready set of features (e.g. "Phase 3: events/jobs/ads", "Phase 4: Brevo sign-in").
  This is the number people see as "the version" (`v1.2.0`).
- **third number** — always `0`. It exists only so the version string has the conventional
  three parts; day-to-day iteration is tracked by `+BUILD` instead (see below), not by this digit.
- **+BUILD** (the "internal id") — increments by exactly 1 for every build that gets installed on
  a device or uploaded anywhere (a GitHub Release, Play Console, a tester's phone). **Never reset
  or reuse a build number** — Play Console rejects an upload whose build number isn't strictly
  higher than every build number it has already seen for that app, even in closed testing.

Bump the version before pushing, in its own commit, matching what's about to ship:

```yaml
version: 1.2.0+7   # MAJOR=1, PRODUCTION=2, always-0, BUILD=7
```

**GitHub Releases are fully automated — don't create them by hand.** `.github/workflows/ci.yml`
already runs `flutter analyze` + `flutter test`, builds an obfuscated release APK, and publishes a
GitHub Release on every push to `main`, tagged `v{pubspec version}-{run number}` (e.g.
`v1.2.0+7-21`) with `make_latest: true` and the APK attached as both `myharur.apk` and
`app-release.apk`. Every CI run gets its own release and keeps its own APK downloadable — this is
deliberate, so a bad build can be rolled back to a specific prior run rather than only ever having
"the latest." `web/index.html`'s download button points at
`.../releases/latest/download/myharur.apk`, which always resolves to whatever CI most recently
published, regardless of that release's exact tag name. Bumping the `version:` number is still
what you do by hand — the tag and the release itself are the workflow's job, not yours.

## 1. Backend

**Production (`qpuvhhvzygdbvlichbqs`) is migrated** — baseline + moderation pipeline + function hardening are applied and tracked
(`npx supabase migration list --linked` shows all three). pg_cron is enabled and the 15-minute expiry sweep is scheduled.

Day-to-day workflow (CLI is logged in and linked; no global install needed):

```bash
npx supabase migration new <name>          # add a file under supabase/migrations/
python supabase/tests/moderation_test.py   # test it on a throwaway Postgres first (see README)
npx supabase db push --linked --dry-run    # see what would apply
npx supabase db push --linked              # apply
npx supabase db advisors --linked --type security
npx supabase db query --linked "select …"  # ad-hoc read-only checks (avoid pulling user PII)
```

Migrations applied so far are listed by `npx supabase migration list --linked`; the security model, findings and the
dashboard checklist are in `docs/SECURITY.md`; push notification setup is in `docs/NOTIFICATIONS.md`.
Release builds are obfuscated (`--obfuscate --split-debug-info=build/symbols`, done in CI): keep the symbols artifact.

Still to do by hand:

1. **Staff access is managed in the app.** The owner account is a super admin (granted once with SQL). Super admins add
   admins and moderators in Account > Staff tools > Admin panel > Users and roles. Staff sign in with Google, then set a
   password in Account > Security so email + password works too.
2. Add Tamil / Tanglish words to `profanity_wordlist` (script `tamil_unicode` or `tamil_tanglish`).
3. Auth → URL configuration: `com.myharur.app://login-callback` must be in the allowed redirect URLs.
   Auth → Providers → Google: the app signs in through the browser (`signInWithOAuth`), so Supabase needs a Google
   **"Web application"** OAuth client (with Supabase's `…/auth/v1/callback` as an authorized redirect URI). An
   *Android*-type client ID (the `kAndroidOAuthClientId` in `auth_service.dart` is one; it is unused) will not work for this flow.
   Test Google sign-in on a real phone.

Expected advisor notes (intentional): `is_staff`/`is_admin` callable by anon+authenticated (RLS needs it), `moderate_alert` and
`delete_my_account` callable by signed-in users (they check permissions inside), `rls_auto_enable` (Supabase's own).

## 2. Signing key (once, keep it forever)

```bash
keytool -genkey -v -keystore ~/myharur-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Create `android/key.properties` (gitignored):

```
storeFile=/absolute/path/to/myharur-upload.jks
storePassword=…
keyAlias=upload
keyPassword=…
```

Back up the `.jks` and passwords somewhere safe (password manager). Enrol in **Play App Signing** when you create the app
so a lost upload key can be reset by Google.

For CI: base64 the keystore and add repo secrets `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`,
`ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`. CI then also produces a signed `.aab`.

## 3. Build

One-time machine setup: install **Android SDK Command-line Tools** (Android Studio → SDK Manager → SDK Tools).
Without it `flutter build appbundle` still produces the `.aab` but prints
"Failed to find cmdline-tools … failed to strip debug symbols" and exits 1. (CI runners already have it.)


```bash
# bump `version:` in pubspec.yaml first — the number after + is the Play versionCode and must increase every upload
flutter build appbundle --release        # → build/app/outputs/bundle/release/app-release.aab
```

## 4. Play Console

- [ ] Developer account; create app `com.myharur.app`.
- [ ] **Closed testing first.** New personal developer accounts must run a closed test with enough testers for ~14 days before
      production access (rule as of last check — confirm the current numbers in Play Console).
- [ ] **Privacy policy** URL (public page). Must cover: email, name, phone, blood group, emergency contact, ward, alerts you post.
- [ ] **Data safety form**: data collected = account info, contact info, health info (blood group), user-generated content;
      encrypted in transit; users can request deletion.
- [ ] **Account deletion**: in-app (Account → Delete Account, done) **and** a public web page/URL explaining how to delete
      the account and what is removed (Play requires both).
- [ ] **User-generated-content policy**: you have automated filtering + human review + audit log. Still missing: an in-app
      **"Report this alert"** button for the public feed and a way to block/report abusive users. Add before production.
- [ ] Content rating questionnaire, target audience (not for children), app category.
- [ ] **Target API level**: check the current Play requirement against `flutter.targetSdkVersion` for the installed Flutter
      (`flutter upgrade` if it is behind).
- [ ] Store listing: icon = `assets/brand/play_store_icon_512.png` (ready), feature graphic 1024×500 (still to make), ≥2 phone screenshots, short + full description.

## 5. Sanity test on a real phone before every release

1. Fresh install → Google sign-in → onboarding → Home shows alerts.
2. Submit an alert → "sent for review" message; it does **not** appear in the feed.
3. As moderator: Review tab shows it (flags visible) → Approve → appears in feed for everyone.
4. Submit an alert containing a blocked word → immediate "language isn't allowed" message.
5. Explore → tap an emergency number → dialer opens.
6. Account → Delete Account (use a throwaway account).
