# MyHarur security and identity model

## 1. Passwords and secrets

- Never store plaintext passwords.
- Never encrypt passwords for later decryption.
- Use Supabase Auth's password handling for staff and resident accounts; do not build a parallel password table.
- If a custom credential service is ever introduced, it must use Argon2id with a library-managed salt, a server-side pepper stored outside the database, rate limiting, breach checks, and rehashing support.
- Store only the Flutter Supabase URL and publishable key in the app. Service-role keys, database connection strings, OAuth client secrets, signing keys, and webhook secrets stay in Supabase Vault, GitHub Actions secrets, or the deployment provider's secret store.
- Do not log passwords, refresh tokens, MFA secrets, emergency images, or full location coordinates.

## 2. Role model

Roles are additive and permission-based:

```text
Member
  -> Moderator
  -> Admin
  -> Government Official (Admin permissions + official publishing permissions)
  -> Super Admin (platform control)

Shop Admin and temporary Event Head/Organizing Secretary are separate additive roles.
```

The database, not the client, enforces these rules:

- Maximum three active super-admin accounts.
- Exactly one primary super-admin.
- Primary super-admin cannot delete itself or be removed by ordinary account termination.
- Super-admin MFA enrollment and assurance are mandatory.
- Role promotion creates an `AID` record; demotion revokes the active identifier without deleting audit history.
- Account termination by admin requires three distinct eligible admin approvals. Super-admin termination follows the primary/super-admin invariants and is not a normal user delete.
- Government publishing, emergency response, and chat moderation are separate permissions even when inherited from a role.

All role and account changes use a transaction, authorization check, approval rule, and append-only audit event.

## 3. Identity identifiers

- Internal UUID: immutable primary key, visible if the product requires it.
- MMID: server-generated, unique, human-readable identifier containing a UTC time component, random four-digit component, and suffix. It is not a replacement for the UUID and must not encode sensitive personal data.
- Username: normalized lowercase unique handle, supports `@` mentions in chat.
- AID: server-generated active administrator identifier; old identifiers remain revoked in audit history.

Uniqueness is enforced with database constraints, not only client validation.

## 4. Username safety

Before reservation or rename:

1. Unicode-normalize and case-fold the candidate.
2. Reject invisible/control characters, lookalike-confusable variants, impersonation patterns, and excessive punctuation.
3. Check exact and normalized reserved names for government, police, administration, system, news, support, help, admin, superadmin, moderator, mod, API, verification, and future protected names.
4. Check a versioned English, Hindi, and Tamil blocked-term list plus transliteration variants.
5. Route uncertain matches to admin review rather than claiming perfect language coverage.

The display name is screened separately. False positives need an appeal path; the filter is a safety layer, not the sole moderation control.

## 5. Location and emergency privacy

- Ask for location only when a feature needs it.
- Store a service-area selection for normal personalization.
- Use exact coordinates only for an active, consented emergency request, with a retention/expiry policy.
- Fan-out radii: 1 km, then 5 km, then 10 km, each with a bounded time window and deduplicated notifications.
- Never expose a requester's exact coordinates to all nearby users; responders receive the minimum needed information.
- Government responders see only cases assigned to their jurisdiction/permission scope.
- Every view, response, status change, and media access is auditable.

## 6. Abuse controls

- Per-user and per-IP rate limits for login, username checks, posts, messages, emergency requests, image uploads, and votes.
- Idempotency keys for emergency creation, payment callbacks, moderation actions, and scheduled ingestion.
- Moderation queue and report/appeal trail.
- Spam and duplicate detection for news, events, marketplace listings, and chat.
- Server-side validation of all role, status, price, expiry, and ownership transitions.

