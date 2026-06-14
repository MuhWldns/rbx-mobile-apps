# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Flutter mobile app (`rbx_mobile_apps`, "RBX Royale") that talks to the backend at `https://api-rbx.muhwldns.me`. Dart SDK `^3.11.4`. Three signed-in tabs (Dashboard, Top Up, Profile) plus a Login screen, shipped against Android primarily (iOS/macOS/Linux/Windows/Web folders are stock Flutter scaffolding).

## Commands

```bash
flutter pub get                              # install deps
flutter run                                  # run on the connected device/emulator
flutter analyze                              # lint via package:flutter_lints/flutter.yaml
flutter test                                 # run all tests in test/
flutter test test/services/topup_service_test.dart           # single file
flutter test --plain-name 'API base URL is correct'          # single test by name
flutter build apk                            # release Android build
```

## Architecture

### Auth: Bearer JWT via system browser

Login uses `flutter_web_auth_2` to open the OAuth provider in a Custom Tab / `ASWebAuthenticationSession`, **not** a WebView. The flow:

1. `LoginPage` calls `authProvider.loginWithGoogle()` / `loginWithDiscord()`, which delegates to `AuthService` (`lib/auth/auth_service.dart`).
2. `AuthService` opens `https://api-rbx.muhwldns.me/auth/<provider>?platform=mobile` in the system browser via `flutter_web_auth_2`.
3. After the provider OAuth completes, the backend redirects to the deep link `rbxroyale://auth?access=<JWT>&refresh=<opaque>` (or `?error=oauth_failed` on failure). The Android intent filter for this scheme is in `android/app/src/main/AndroidManifest.xml`.
4. `AuthService` parses the deep link, persists `access` and `refresh` to `AuthStorage` (Keychain/EncryptedSharedPreferences), and `AuthProvider` fetches `/auth/me` via `UserService`.

Why system browser: Google blocks WebView OAuth with `disallowed_useragent`, and a real browser is more secure (user's existing Google session is reused, kredensial never lewat app).

### HTTP client: Dio + AuthInterceptor

`lib/auth/dio_client.dart` exposes `buildAuthStack()` which constructs:
- A `Dio` instance with `baseUrl: AppConstants.apiBaseUrl`, `validateStatus: (s) => s != null && s < 500` (services decode error bodies themselves).
- An `AuthInterceptor` (`lib/auth/auth_interceptor.dart`) that attaches `Authorization: Bearer <access>` to every outgoing request.
- An `AuthService` wired against the same Dio.

When a request returns `401 { "error": "token_expired" }`, the interceptor calls `AuthService.refreshAccessToken()` (which posts to `/auth/refresh` with the rotated refresh token), then retries the original request once with the new access token. Other 401 codes (`invalid_token`, `refresh_invalid`) bubble up — `refresh_invalid` from the refresh endpoint itself wipes storage so the router pushes the user back to login.

Bypass header: callers that must NOT be intercepted (the refresh and logout-mobile calls inside `AuthService`) set `X-Skip-Auth-Interceptor: '1'`. The interceptor strips that header and skips both the bearer attach and the 401 retry path.

### Services

All services take a `Dio` via constructor and live under `lib/services/`:
- `UserService.fetchMe()` (returns `User?`) and `saveRobloxId(...)` — `/auth/me` and `/user/roblox-id`
- `TopUpService.createTopUp(...)` and `getStatus(reference)` — `/topup/create` and `/topup/status/<ref>`
- `LicenseService.fetchLicenses()` — `/licenses`

There is no service-locator. `main.dart` builds `AuthStack`, constructs each service against `stack.dio`, and provides them through `MultiProvider`. Pages read services via `context.read<TopUpService>()` etc. Add new services in this same shape.

### State + routing

- `AuthProvider` (`ChangeNotifier`) is the single source of truth for `user` and `isLoading`. Constructed with `authService` + `userService` deps, created in `main.dart` *before* `runApp`, `init()` awaited, then provided via `ChangeNotifierProvider.value`.
- `AuthProvider.init()` checks `authService.isLoggedIn()` (token present in storage), and if so calls `userService.fetchMe()`. The interceptor handles refresh transparently; only when the token chain is fully dead does `fetchMe()` return null, which triggers `authService.logout()` to wipe storage so the router lands on `/login`.
- `createRouter(authProvider)` (`lib/router/app_router.dart`) builds a `GoRouter` that uses `authProvider` as `refreshListenable`. The `redirect` callback gates everything: while `isLoading` it returns `null` (no redirect), otherwise it forces `/login` ↔ `/dashboard` based on `isAuthenticated`.
- Authenticated routes (`/dashboard`, `/topup`, `/profile`) live inside a `ShellRoute` whose builder is `AppShell` (bottom nav). `/login` is outside the shell.
- Pages read state via `context.watch<AuthProvider>()` and trigger refreshes by calling `authProvider.refreshUser()` (e.g. after a top-up succeeds in `topup_page.dart`).

### Top-up polling

`TopUpPage` is a small state machine (`TopUpStep` enum: `input → processing → qris → success/failed/timeout`). Once the QRIS payment is created it polls `GET /topup/status/{ref}` every 3s with a 5-min hard timeout, and on `paid`/`COMPLETED` calls `AuthProvider.refreshUser()` so the wallet balance updates everywhere. Cancel both `_pollingTimer` and `_countdownTimer` in `dispose`.

### Theming

`lib/core/theme.dart` `AppTheme` is the only place that should define colors/gradients — pages and widgets reference `AppTheme.violet`, `AppTheme.primaryGradient`, etc. Reusable building blocks: `PanelCard` (glassmorphism container) and `GradientButton` (violet→fuchsia primary CTA). Match this style for any new UI rather than introducing fresh palettes.

## Constants

All API endpoints, OAuth callback scheme, and storage keys live in `lib/core/constants.dart` (`AppConstants`). Add new endpoints there rather than inlining URLs in services. Key tokens:
- `oauthCallbackScheme = 'rbxroyale'` — must match the AndroidManifest intent filter and the backend's `MOBILE_DEEP_LINK_REDIRECT` env.
- `oauthMobileQueryParam = '?platform=mobile'` — appended to `/auth/google` and `/auth/discord` to trigger the deep-link callback path on the backend.
- `storageAccessTokenKey` / `storageRefreshTokenKey` — keys used by `AuthStorage` against `flutter_secure_storage`.

## Tests

Tests mirror `lib/` under `test/` (e.g. `test/auth/auth_service_test.dart` for `lib/auth/auth_service.dart`, `test/services/topup_service_test.dart` for `lib/services/topup_service.dart`). They cover:
- `AuthStorage` save/read/clear via a mocked `flutter_secure_storage` MethodChannel
- `AuthService` login/refresh/logout via a stub `FlutterWebAuth2Authenticator` and a Dio `_CannedAdapter`
- `AuthInterceptor` bearer attach + 401 token_expired refresh+retry via a `_ScriptedAdapter`
- Service JSON parsing and HTTP behavior via canned Dio adapters
- Page widget tests with `FakeAuthProvider` + injected service Providers
- No integration tests against a live backend.

## Implementation plan archive

The migration from cookie+WebView to bearer JWT was executed against the plan in `docs/superpowers/plans/2026-06-14-mobile-bearer-auth.md` (master) and the four chunk files under `docs/superpowers/plans/2026-06-14-mobile-bearer-auth/`. Refer to those for the rationale behind specific code shapes if a future change touches the auth stack.
