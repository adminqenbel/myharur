# E-mail / phone sign-in via Brevo

Google sign-in stays primary. This adds two more ways in: a 6-digit code sent to an e-mail
address, or to a phone number, delivered through Brevo's free transactional e-mail/SMS APIs.
Everything on the code side is already built and tested; the steps below are the ones only you
can do (a Brevo account and a few Supabase dashboard clicks). Until they're done the two new
buttons on the sign-in screen will fail with a generic "couldn't send the code" error — nothing
else in the app is affected.

## Why this design

Rather than building a custom one-time-code system, the app uses Supabase Auth's own e-mail/phone
OTP sign-in (`signInWithOtp` / `verifyOTP`) — it already generates, hashes, expires and
rate-limits the code itself, the same trusted mechanism used by thousands of apps. Only the
*delivery* is swapped: two Supabase **Auth Hooks** (edge functions already deployed —
`send-email-hook`, `send-sms-hook`) intercept the code right before Supabase would send it and
send it through Brevo instead. A per-identifier and whole-app daily cap runs inside each hook
*before* calling Brevo, so a burst of requests can't run up the bill.

Both a brand-new resident and someone signing back in use the exact same button — Supabase
creates the account on first verification, same as Google sign-up always has, and it goes
through the normal username/profile/occupation onboarding afterwards.

## 1. Create a Brevo account and API key

1. Sign up at [brevo.com](https://www.brevo.com) (free plan: 300 e-mails/day; SMS is pay-as-you-go,
   there is no free SMS quota).
2. **Senders & IP** > **Senders** > add and verify a sender e-mail address (e.g.
   `noreply@yourdomain.com`, or your own inbox while testing). Brevo will e-mail you a
   confirmation link — click it before anything will send.
3. **SMS campaigns** > check India is enabled for transactional SMS on your account (may need ID
   verification for some countries; check Brevo's current requirements).
4. **Settings (top-right) > SMTP & API > API Keys** > **Generate a new API key**. Copy it —
   you won't see it again.

## 2. Set the secrets yourself (never paste them in chat)

From your own terminal, with the Supabase CLI already logged in and linked to this project:

```bash
supabase secrets set BREVO_API_KEY="<the key from step 1.4>"
supabase secrets set BREVO_SENDER_EMAIL="<the verified sender from step 1.2>"
supabase secrets set BREVO_SENDER_NAME="MyHarur"
supabase secrets set BREVO_SMS_SENDER="MyHarur"
supabase secrets set OTP_HASH_PEPPER="<any long random string, e.g. from `openssl rand -hex 32`>"
```

Optional, only if you want different daily caps than the defaults (300 e-mails/day, 50 SMS/day):

```bash
supabase secrets set OTP_EMAIL_DAILY_CAP="300"
supabase secrets set OTP_SMS_DAILY_CAP="50"
```

## 3. Deploy the two hook functions

```bash
supabase functions deploy send-email-hook --no-verify-jwt
supabase functions deploy send-sms-hook --no-verify-jwt
```

(`--no-verify-jwt` is correct here — Auth Hooks are called by Supabase itself, not by a signed-in
user, and are protected instead by the Standard Webhooks signature set up in the next step.)

## 4. Wire the hooks up in the Supabase dashboard

**Authentication > Hooks** (sometimes called "Auth Hooks" or under "Extensibility"):

1. **Send Email hook** — enable it, type **HTTPS**, point it at
   `https://qpuvhhvzygdbvlichbqs.supabase.co/functions/v1/send-email-hook`. The dashboard shows a
   signing secret starting `v1,whsec_...` — copy the whole thing and run:
   ```bash
   supabase secrets set SEND_EMAIL_HOOK_SECRET="v1,whsec_...."
   ```
2. **Send SMS hook** — same steps, pointing at `.../functions/v1/send-sms-hook`, secret set as
   `SEND_SMS_HOOK_SECRET`.

**Authentication > Providers > Phone**: turn it on. No SMS provider (Twilio/MessageBird/etc.)
needs to be configured underneath it — the Send SMS hook replaces that entirely.

**Authentication > Providers > Email**: make sure "Allow new users to sign up" is on (it already
is, since Google registration needs it) and OTP/magic link is enabled — it is by default.

## 5. Try it

In the app, Sign in or Register > "Continue with email" or "Continue with phone" > enter the
address/number > you should get a code within a few seconds > entering it signs you in (or, for a
number/address nobody has used before, creates a fresh account and starts onboarding, same as a
first Google sign-in).

If it fails, check (in order): the two secrets from step 2 are set (`supabase secrets list` shows
names, not values), the sender e-mail is verified in Brevo, the two hooks show as "Enabled" with a
green status in the dashboard, and the Supabase function logs for `send-email-hook`/`send-sms-hook`
for the actual error.

## What changed to make this possible

A trigger added on 2026-09-27 (`block_email_signup`) deliberately rejected any new account created
through GoTrue's "email" identity, specifically to stop the public API key being used to farm
accounts via the raw `auth.signUp(email, password)` endpoint while Google was the only intended
sign-up path. E-mail OTP sign-up uses that same "email" identity internally, so that trigger would
have rejected every legitimate OTP sign-up too — it's been dropped (migration
`20261009000100_brevo_otp_auth.sql`) now that a real, rate-limited e-mail path exists. The app
itself still never exposes a raw password sign-up screen, and reaching the old endpoint directly
still requires actually controlling the e-mail address to ever get a confirmed, usable session —
the same bar OTP sign-up sets.

## Notifications keep working

`FIREBASE_SERVICE_ACCOUNT` (push notifications, see `docs/NOTIFICATIONS.md`) is unrelated to any
of this — Brevo only carries sign-in codes, never push notifications.
