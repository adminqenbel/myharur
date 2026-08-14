# MyHarur

MyHarur is a secure digital-town app for Harur, Dharmapuri, and surrounding Tamil Nadu communities.

The repository is currently in the architecture and planning phase. The implementation will use Flutter for the client and Supabase for managed authentication, PostgreSQL, Row Level Security, storage, realtime features, and server-side functions.

## Current documents

- [Product plan](docs/PRODUCT_PLAN.md)
- [System architecture](docs/ARCHITECTURE.md)
- [Security and identity](docs/SECURITY.md)
- [Delivery phases](docs/DELIVERY_PHASES.md)
- [UI direction](docs/UI_DIRECTION.md)

## Secret handling

Do not commit database connection strings, database passwords, Supabase service-role keys, OAuth client secrets, signing keys, or API tokens. Local secrets belong in ignored environment files or in the deployment provider's secret store. The Flutter client may contain only the Supabase URL and publishable/anon key, protected by database RLS and function authorization.

