# Mobile Bearer-Auth Migration — Implementation Plan (Master Index)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Execute chunks in order — each chunk's tasks depend on the previous chunk having compiled and committed cleanly.

**Goal:** Migrate the Flutter app from cookie-based session auth (WebView extraction) to Bearer JWT auth (system browser + access/refresh token pair) per the backend integration guide.

**Architecture:** System browser (`flutter_web_auth_2`) opens `/auth/<provider>?platform=mobile`, backend redirects to `rbxroyale://auth?access=...&refresh=...`. Tokens stored in `flutter_secure_storage`. All HTTP traffic flows through a single `Dio` instance with an `AuthInterceptor` that attaches `Authorization: Bearer <access>` and silently refreshes on `token_expired` 401s. UI layer (pages, widgets, theme) is untouched — only services and the auth/storage layer change.

**Tech Stack:** Flutter (Dart `^3.11.4`), Dio 5, flutter_web_auth_2 3.x, flutter_secure_storage 9.x, Provider, GoRouter.

---

## Why this is split into chunks

Each chunk is a self-contained, committable unit that leaves the codebase compiling and testable. Execute in order:

| Chunk | File | Scope | Outcome after chunk |
| ----- | ---- | ----- | ------------------- |
| 1 | [`01-foundations.md`](2026-06-14-mobile-bearer-auth/01-foundations.md) | Deps, AndroidManifest, `AuthStorage`, constants | App still compiles + old flow still works; new storage class is unit-tested but unused. |
| 2 | [`02-auth-core.md`](2026-06-14-mobile-bearer-auth/02-auth-core.md) | `AuthService` (login/refresh/logout), `AuthInterceptor`, Dio factory | New auth core is built and unit-tested; still nothing wired into UI. |
| 3 | [`03-service-migration.md`](2026-06-14-mobile-bearer-auth/03-service-migration.md) | Move `TopUpService` / `LicenseService` / `/auth/me` to Dio; delete old `ApiClient` | All network code uses Dio; old http_client + old auth_service deleted. Compiles, but `AuthProvider` & `LoginPage` still reference removed APIs — those are fixed in chunk 4 (a single failing-build window between chunks 3 and 4 is acceptable). |
| 4 | [`04-ui-integration.md`](2026-06-14-mobile-bearer-auth/04-ui-integration.md) | Rewrite `AuthProvider`, `LoginPage`, `main.dart`; delete `auth_webview.dart` & `flutter_inappwebview` dep; manual smoke test | App fully migrated. |

> **Build state between chunks:** Chunks 1, 2, and 4 each leave the project building. Chunk 3 is the one transition where you must finish chunk 4 before `flutter analyze` is fully clean again — chunk 4's first task is the import fixes that close the window. Don't push chunk 3 to `main` without chunk 4 right after.

---

## Pre-flight (do once, before chunk 1)

- [ ] **Read the backend integration guide** included in the conversation (Mobile Integration Guide — Bearer Auth). All endpoint contracts, error shapes, deep link format, and the canonical Dart code for `AuthStorage` / `AuthService` / `AuthInterceptor` come from there.
- [ ] **Confirm backend endpoints are live:** `GET /auth/google?platform=mobile`, `GET /auth/discord?platform=mobile`, `POST /auth/refresh`, `POST /auth/logout-mobile` against `https://api-rbx.muhwldns.me`. If any are not deployed yet, stop and escalate before starting chunk 1 — there is nothing useful to test against.
- [ ] **Confirm deep-link target:** backend env `MOBILE_DEEP_LINK_REDIRECT` is `rbxroyale://auth` (default). If it's something else, the AndroidManifest entry in chunk 1 needs to match.
- [ ] **Working directory clean:** `git status` should show only the pre-existing platform-folder noise from CLAUDE.md context (`linux/`, `macos/`, `windows/` regenerated plugin registrants). Stash anything else.

---

## Code-style notes that apply to every chunk

- **Theme & widgets unchanged.** Do not touch `lib/core/theme.dart`, `lib/widgets/panel_card.dart`, `lib/widgets/gradient_button.dart`, or any page's visual code. Color/gradient references stay as-is.
- **Endpoints in `AppConstants`.** Any new path string (`/auth/refresh`, `/auth/logout-mobile`) lives in `lib/core/constants.dart`, not inline.
- **Singleton-by-DI, not by global.** The old `ApiClient` was a `factory` singleton. The new world wires `Dio`/`AuthService`/`AuthStorage` from `main.dart` and passes them down via constructor or `Provider`. No service-locator pattern, no top-level globals.
- **Tests mirror `lib/`.** New code under `lib/auth/` gets tests under `test/auth/` (matching CLAUDE.md test convention).
- **Commit per task.** Every task ends in a commit. Don't batch.

---

## Self-review (before handing off to executor)

- Spec coverage: every section of the integration guide (§3 manifest, §4 deps, §5 auth service code, §6 UI flows, §9 pre-flight checklist) is covered by a task in some chunk.
- Placeholder scan: no "TBD", no "implement appropriate handling" — every code step shows the actual code.
- Type consistency across chunks: `AuthStorage.save({access, refresh})`, `AuthService.refreshAccessToken()` (returns `Future<bool>`), `AuthService.loginWithGoogle()` / `loginWithDiscord()`, `AuthService.logout()`, `AuthService.isLoggedIn()`, `AuthInterceptor` honors `X-Skip-Auth-Interceptor: '1'`. These names are used identically in chunks 1–4.

---

## Execution handoff

Plan complete and saved to `docs/superpowers/plans/2026-06-14-mobile-bearer-auth.md` (this file) plus four chunk files under `docs/superpowers/plans/2026-06-14-mobile-bearer-auth/`. Two execution options:

1. **Subagent-Driven (recommended)** — dispatch a fresh subagent per chunk (or per task), review between chunks. Best for keeping the parent context clean.
2. **Inline Execution** — execute chunks in this session using `superpowers:executing-plans`, with a checkpoint after each chunk.

Tell me which approach when you're ready to start.
