# Frontend UI & UX Specification (V4)

## Global Design Language
- **Typography**: "Plus Jakarta Sans" exclusively. No system fonts.
- **State Management**: Riverpod (`ConsumerStatefulWidget`, `StateNotifier`).
- **Navigation**: GoRouter (declarative deep-linkable navigation).

## Theme Tokens
- **Dark Theme Palette**: 
  - Background: `#081C2D`
  - Surface Cards: `#16324F`
  - Accent Active: `#F4B400` (Yellow)
- **Border Radii**: Cards use `20px`. Buttons use `16px`.

## Modern Bottom Navigation (Telegram Inspired)
- **Structure**: Floating, separated from the device bottom edge via `SafeArea` and padding.
- **Glassmorphism**: Built using `BackdropFilter(sigmaX: 18, sigmaY: 18)` inside a `ClipRRect`.
- **Active State Indicators**: Selected tabs use a rounded yellow pill (`AnimatedContainer`) that dynamically scales by `10%` utilizing `AnimatedScale`.
- **Keyboard Handling**: Navigation bar automatically unmounts (`isKeyboardOpen ? null : ...`) via `MediaQuery.viewInsets` to prevent obstructing text fields.

## Client-Side Authentication Flow
1. API endpoints are requested via a singleton `ApiClient` using `Dio`.
2. Bearer tokens are dynamically injected via `InterceptorsWrapper`.
3. Guest mode generates a mock token (`guest_mode`), bypassing GoRouter's strict login redirect and degrading API access smoothly via backend 401 Unauthorized responses.
4. Token storage is persisted securely across app restarts.
