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

### Auth + session model (the unusual part)

The backend uses an httpOnly `connect.sid` session cookie. OAuth login is *not* done via deep links — it happens entirely inside an in-app WebView:

1. `LoginPage` pushes `AuthWebView` (`lib/widgets/auth_webview.dart`) pointed at `/auth/google` or `/auth/discord`.
2. After the provider redirects back, the backend lands on a URL containing `login=success`. The WebView intercepts this in `shouldOverrideUrlLoading` / `onLoadStop`.
3. `flutter_inappwebview`'s `CookieManager.getCookies()` is used to read the httpOnly `connect.sid` cookie out of the WebView's cookie jar (this is the only reason `flutter_inappwebview` is used instead of plain webview — `webview_flutter` cannot read httpOnly cookies). It checks both the API URL and the bare `https://muhwldns.me` domain.
4. The cookie string (`connect.sid=...`) is handed back to `AuthProvider.onSessionObtained`, which persists it through `ApiClient` and fetches `/auth/me`.

If you change the OAuth flow, also use a non-WebView UA — `auth_webview.dart` overrides the user agent to a Chrome-on-Pixel string because Google blocks default WebView UAs with `disallowed_useragent`.

### HTTP client

`lib/core/http_client.dart` is a singleton `ApiClient` that:
- Loads the saved cookie from `flutter_secure_storage` on `init()`.
- Attaches `Cookie: connect.sid=...` to every request.
- Inspects every response's `Set-Cookie` and re-persists `connect.sid` if the server rotates it.

All services (`AuthService`, `LicenseService`, `TopUpService`) call `ApiClient()` (same instance) and decode JSON inline. There is no `Dio`/interceptor layer — keep new endpoints in this style.

### State + routing

- `AuthProvider` (`ChangeNotifier`) is the single source of truth for `user` and `isLoading`. It is created in `main.dart` *before* `runApp`, `init()` is awaited, then provided via `ChangeNotifierProvider.value`.
- `createRouter(authProvider)` (`lib/router/app_router.dart`) builds a `GoRouter` that uses `authProvider` as `refreshListenable`. The `redirect` callback gates everything: while `isLoading` it returns `null` (no redirect), otherwise it forces `/login` ↔ `/dashboard` based on `isAuthenticated`.
- Authenticated routes (`/dashboard`, `/topup`, `/profile`) live inside a `ShellRoute` whose builder is `AppShell` (bottom nav). `/login` is outside the shell.
- Pages read state via `context.watch<AuthProvider>()` and trigger refreshes by calling `authProvider.refreshUser()` (e.g. after a top-up succeeds in `topup_page.dart`).

### Top-up polling

`TopUpPage` is a small state machine (`TopUpStep` enum: `input → processing → qris → success/failed/timeout`). Once the QRIS payment is created it polls `GET /topup/status/{ref}` every 3s with a 5-min hard timeout, and on `paid`/`COMPLETED` calls `AuthProvider.refreshUser()` so the wallet balance updates everywhere. Cancel both `_pollingTimer` and `_countdownTimer` in `dispose`.

### Theming

`lib/core/theme.dart` `AppTheme` is the only place that should define colors/gradients — pages and widgets reference `AppTheme.violet`, `AppTheme.primaryGradient`, etc. Reusable building blocks: `PanelCard` (glassmorphism container) and `GradientButton` (violet→fuchsia primary CTA). Match this style for any new UI rather than introducing fresh palettes.

## Constants

All API endpoints and the cookie key live in `lib/core/constants.dart` (`AppConstants`). Add new endpoints there rather than inlining URLs in services. The session cookie name (`connect.sid`) and storage key (`session_cookie`) are defined here too — keep them in sync with backend changes.

## Tests

Tests mirror `lib/` under `test/` (e.g. `test/services/topup_service_test.dart` for `lib/services/topup_service.dart`). They cover constants, model JSON parsing, and provider state — there are no integration tests against a live backend.
