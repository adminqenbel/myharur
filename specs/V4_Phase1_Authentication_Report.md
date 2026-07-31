# My Harur V4.0 - Phase 1: Authentication Module Report

## 1. Authentication Analysis & Implementation
The Authentication module was analyzed and optimized in-place without rewriting the entire core. 
- **Normal Users:** Google Sign-in is mandated as the primary auth. Email/Password login forms have been visually disabled and locked behind the `Admin / Staff Login` toggle.
- **Admin/Staff Users:** Administrators can now authenticate using either their explicitly assigned Email or their unique `username`. This streamlines system access. 
- **Identity & MMID:** The system previously used a sequential counter for MMIDs (e.g., `20260726163001`). This was vulnerable to race conditions and enumeration. The MMID generation algorithm has been updated to generate a globally unique identifier using the exact V4 spec: `YYYYMMDDHHMMSS + Random4Digits`.

## 2. Security Improvements
- **Username Validation:** The username registration regex has been strictly limited to `^[a-zA-Z0-9_\.]{3,30}$`, explicitly blocking unicode spoofing, zero-width characters, emojis, and spaces while permitting periods (`.`) and underscores (`_`). 
- **Bad Word & Reservation Filters:** Integrated the provided list of 47 reserved handles (`admin`, `police`, `hospital`, `news`, etc.) alongside a comprehensive profanity filter. 
- **Session Management:** We implemented robust session tracking using Redis. Tokens generated upon login are mapped to specific device signatures (`User-Agent`).
- **Global Session Revocation:** Created a `POST /auth/logout-all` endpoint and linked it to the Flutter `AuthNotifier`. If an admin detects a compromised account, they can instantly terminate all active Redis sessions globally.

## 3. Performance Improvements
- **JWT & Redis Lookups:** By pushing active session management entirely into Redis, we have bypassed the need for expensive PostgreSQL lookups to validate token lifecycle (preventing database bottlenecks during heavy concurrent logins).
- **Latency Optimization:** The Google Authentication pipeline has been streamlined to upsert users directly into the database in a single transaction, bypassing redundant profile queries. 

## 4. Migration Report
- No breaking schema changes were introduced.
- Historical user MMIDs (using the 12-digit format) will remain active and intact, ensuring 100% backward compatibility for existing users.
- New users will automatically receive the new 18-digit MMID.
- The `is_username_available` API endpoint has been kept backward compatible.

## 5. Testing Checklist
- [x] Verify normal users can only sign in via Google or Guest mode.
- [x] Verify Admins can log in using either `username` or `email`.
- [x] Create a new account and verify MMID format is `YYYYMMDDHHMMSS + 4RandomDigits`.
- [x] Attempt to claim a reserved username (e.g., `admin`, `system`) and verify rejection.
- [x] Attempt to claim an abusive username and verify rejection.
- [x] Attempt to use emojis or unicode in the username and verify rejection.
- [x] Test `logoutAll()` and verify the Redis keys are flushed.
- [x] Recompile the Flutter APK and confirm the UI changes on the Login Screen.
