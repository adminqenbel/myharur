# MyHarur product plan

## 1. Product objective

Create a trusted, mobile-first digital town layer for Harur and Dharmapuri: useful local information, verified civic communication, location-aware help, and community participation in one calm interface.

The first release should prove the most important loop:

`discover local information -> take a safe action -> receive a trusted update`

## 2. Product principles

1. Safety before speed: emergency and government workflows must be auditable, permissioned, and resilient when an individual account is unavailable.
2. Local relevance: Harur and Dharmapuri content first; broader Tamil Nadu content is secondary.
3. Human approval where trust matters: user-submitted news, events, reports, and government content must have explicit workflow states.
4. Least privilege: a user may have multiple roles, but each feature checks permissions instead of assuming one global role.
5. Privacy by default: coarse location is enough for discovery; exact location is reserved for consented emergency cases.
6. Free-tier conscious: keep the mobile app stateless, batch ingestion, compress images, and avoid always-on servers.
7. No false security promises: a public mobile app cannot be made impossible to fork; secrets, authorization, data, and operational control must remain server-side.

## 3. Release 1 scope

The first usable release is deliberately narrow:

- Apple-like MyHarur home screen with location, map preview, weather, local news, and emergency entry point.
- Google sign-in for residents.
- Admin-created username/password onboarding for staff roles, followed by profile completion and Google identity linking.
- Profile with UUID, visible MMID, username, roles, and account status.
- News feed with source attribution, image, title, summary, locality, and approval state.
- Weather cards for Harur and Dharmapuri with cached refresh timestamps.
- Manual location selection when the device is outside the supported service region.
- Emergency request creation, image attachment, tracking timeline, and initial nearby-help notification model.
- Admin moderation queue for news, reports, and events.

Everything else remains behind feature flags until its authorization and moderation model is ready.

## 4. Later modules

- Marketplace for one-off used/like-new/new listings.
- Jobs and applications.
- Events and tournaments, registration, event-head role, expiry, and external payment/forms handoff.
- Public and temporary chat rooms with moderation.
- Shop admin, up to two shops by default, product/offer/stock management.
- Government announcements and orders in a separate official publishing area.
- Support bot with escalation to support staff.
- Rankings for helpfulness, activity, donations, restaurants, admins, and shops with anti-abuse controls.
- Donation portal and payment reconciliation.

