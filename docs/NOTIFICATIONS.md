# Push notifications (Firebase Cloud Messaging)

Everything is built and tested; two things only you can supply from the Firebase console switch it on.
Until then the app runs normally and Account > Notifications says notifications are not set up yet.

## What people get

- One short summary a day (about 18:00 India time) when new reports were published, in English or Tamil to match the app.
- Event alerts (when events launch): at most two a week.
- Nothing between 22:00 and 07:00 India time.
- A master switch and one switch per kind, in Account > Notifications. A one-time question after sign-in offers to turn
  it on. The Android permission is requested only when the person says yes.
- These limits are enforced in the database (`internal_digest_plan`, `internal_event_push_allowed`), so a bug in the sender
  cannot exceed them. No filler notifications: if nothing new was published, nothing is sent.

## One-time setup

1. Firebase console > create a project (free Spark plan is enough) > Add app > Android, package name `com.myharur.app`.
   Add the SHA-1 of your debug and release keys if asked.
2. Download **`google-services.json`** and put it at `android/app/google-services.json`.
   (It is a per-project config file, not a secret. Commit it so CI builds include push, or keep it out and CI builds without.)
3. Firebase console > Project settings > Service accounts > **Generate new private key**. This file **is a secret**.
   Do not paste it into chat or commit it. Set it as a function secret from your own terminal:

   ```bash
   supabase secrets set FIREBASE_SERVICE_ACCOUNT="$(cat path/to/service-account.json)"
   ```

   then delete the downloaded file.
4. Rebuild the app. Sign in, Account > Notifications > turn on.

The web push "key pair" (VAPID) you may have seen in Firebase settings is only for browser notifications; it is not needed for Android.

## How it runs

`pg_cron` (job `myharur-push-digest`, 12:30 UTC daily) calls the `push-digest` edge function with the shared cron secret.
The function asks the database for a plan, fetches the tokens of people who kept notifications and Reports on,
sends through FCM HTTP v1 (20 at a time), removes tokens Firebase says are gone, and logs the send. If Firebase is not
configured it answers `push_not_configured` and does nothing.

Manual test (from the Supabase SQL editor; the secret is read from Vault, never typed):

```sql
select net.http_post(
  url := 'https://qpuvhhvzygdbvlichbqs.supabase.co/functions/v1/push-digest',
  headers := jsonb_build_object('Content-Type','application/json',
    'x-cron-secret',(select decrypted_secret from vault.decrypted_secrets where name='myharur_cron_secret')),
  body := '{}'::jsonb);
select status_code, content from net._http_response order by id desc limit 1;
```
