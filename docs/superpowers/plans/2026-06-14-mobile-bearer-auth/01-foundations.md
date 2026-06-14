# Chunk 1 — Foundations

> Part of [Mobile Bearer-Auth Migration](../2026-06-14-mobile-bearer-auth.md). Execute chunks in order.

**Goal of this chunk:** Add new dependencies, set up the Android deep-link intent filter, create the `AuthStorage` class (Keychain/Keystore wrapper), and add new auth-related constants. After this chunk the app still compiles and the old cookie flow still works — none of the new code is wired in yet.

**Files touched:**
- Modify: `pubspec.yaml`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `lib/core/constants.dart`
- Create: `lib/auth/auth_storage.dart`
- Create: `test/auth/auth_storage_test.dart`

---

## Task 1.1: Add new dependencies to `pubspec.yaml`

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Edit pubspec to add dio and flutter_web_auth_2**

In `pubspec.yaml`, replace the `dependencies:` block with:

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  provider: ^6.1.2
  go_router: ^14.8.1
  http: ^1.2.2
  flutter_inappwebview: ^6.1.5
  flutter_secure_storage: ^9.2.4
  intl: ^0.19.0
  dio: ^5.5.0
  flutter_web_auth_2: ^3.1.2
```

(`http` and `flutter_inappwebview` stay for now — they get removed in chunk 4 once nothing references them.)

- [ ] **Step 2: Run `flutter pub get`**

Run: `flutter pub get`
Expected: resolves successfully, prints "Got dependencies!". `pubspec.lock` is updated.

- [ ] **Step 3: Verify the project still analyzes clean**

Run: `flutter analyze`
Expected: "No issues found!" (or the same baseline issues as before this chunk; new deps must not introduce errors).

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add dio and flutter_web_auth_2 deps for bearer auth"
```

---

## Task 1.2: Add `rbxroyale://auth` intent filter to AndroidManifest

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1: Add the intent filter inside `MainActivity`**

In `android/app/src/main/AndroidManifest.xml`, find the existing `<intent-filter>` block under `<activity android:name=".MainActivity">`:

```xml
<intent-filter>
    <action android:name="android.intent.action.MAIN"/>
    <category android:name="android.intent.category.LAUNCHER"/>
</intent-filter>
```

Add a second intent filter directly after it (still inside the same `<activity>`):

```xml
<intent-filter android:autoVerify="false">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="rbxroyale" android:host="auth" />
</intent-filter>
```

- [ ] **Step 2: Verify the project still builds**

Run: `flutter analyze`
Expected: "No issues found!".

(A full `flutter build apk --debug` would also catch manifest errors but is slow; analyze + the next task's compile step is enough at this stage.)

- [ ] **Step 3: Commit**

```bash
git add android/app/src/main/AndroidManifest.xml
git commit -m "feat(android): register rbxroyale://auth deep link intent filter"
```

---

## Task 1.3: Add new auth constants

**Files:**
- Modify: `lib/core/constants.dart`

- [ ] **Step 1: Add new endpoint paths and storage keys**

In `lib/core/constants.dart`, add these constants (keep the existing ones — they stay until chunk 4 deletes the cookie ones):

```dart
class AppConstants {
  AppConstants._();

  static const String apiBaseUrl = 'https://api-rbx.muhwldns.me';
  static const String authGoogle = '$apiBaseUrl/auth/google';
  static const String authDiscord = '$apiBaseUrl/auth/discord';
  static const String authMe = '$apiBaseUrl/auth/me';
  static const String authLogout = '$apiBaseUrl/auth/logout';
  static const String authRefresh = '$apiBaseUrl/auth/refresh';
  static const String authLogoutMobile = '$apiBaseUrl/auth/logout-mobile';
  static const String userRobloxId = '$apiBaseUrl/user/roblox-id';
  static const String topupCreate = '$apiBaseUrl/topup/create';
  static String topupStatus(String reference) =>
      '$apiBaseUrl/topup/status/$reference';
  static const String licenses = '$apiBaseUrl/licenses';

  // Cookie key (legacy — removed in chunk 4 once cookie flow is gone)
  static const String sessionCookieKey = 'connect.sid';

  // Storage keys
  static const String storageCookieKey = 'session_cookie'; // legacy
  static const String storageAccessTokenKey = 'auth_access_token';
  static const String storageRefreshTokenKey = 'auth_refresh_token';

  // OAuth deep-link
  static const String oauthCallbackScheme = 'rbxroyale';
  static const String oauthMobileQueryParam = '?platform=mobile';
}
```

- [ ] **Step 2: Verify analyze**

Run: `flutter analyze`
Expected: "No issues found!".

- [ ] **Step 3: Commit**

```bash
git add lib/core/constants.dart
git commit -m "feat(constants): add bearer auth endpoints and storage keys"
```

---

## Task 1.4: Create `AuthStorage` class

**Files:**
- Create: `lib/auth/auth_storage.dart`

- [ ] **Step 1: Write the file**

Create `lib/auth/auth_storage.dart` with this exact content:

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants.dart';

/// Secure-storage wrapper for the access + refresh JWT pair issued by the
/// backend mobile OAuth flow.
///
/// Tokens are persisted to Keychain (iOS) / EncryptedSharedPreferences
/// (Android). All methods are async and idempotent.
class AuthStorage {
  AuthStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  Future<void> save({
    required String access,
    required String refresh,
  }) async {
    await _storage.write(
      key: AppConstants.storageAccessTokenKey,
      value: access,
    );
    await _storage.write(
      key: AppConstants.storageRefreshTokenKey,
      value: refresh,
    );
  }

  Future<String?> readAccess() =>
      _storage.read(key: AppConstants.storageAccessTokenKey);

  Future<String?> readRefresh() =>
      _storage.read(key: AppConstants.storageRefreshTokenKey);

  Future<void> clear() async {
    await _storage.delete(key: AppConstants.storageAccessTokenKey);
    await _storage.delete(key: AppConstants.storageRefreshTokenKey);
  }

  Future<bool> hasAccess() async {
    final v = await readAccess();
    return v != null && v.isNotEmpty;
  }
}
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze`
Expected: "No issues found!".

- [ ] **Step 3: Commit**

```bash
git add lib/auth/auth_storage.dart
git commit -m "feat(auth): add AuthStorage wrapper for access+refresh tokens"
```

---

## Task 1.5: Test `AuthStorage` with an in-memory fake

**Files:**
- Create: `test/auth/auth_storage_test.dart`

`FlutterSecureStorage` does not work in unit tests without platform channels mocked. We test by injecting a custom `FlutterSecureStorage` whose channel is mocked with `TestDefaultBinaryMessengerBinding`.

- [ ] **Step 1: Write the failing test**

Create `test/auth/auth_storage_test.dart`:

```dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rbx_mobile_apps/auth/auth_storage.dart';
import 'package:rbx_mobile_apps/core/constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // In-memory mock for the flutter_secure_storage MethodChannel.
  late Map<String, String> backing;
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  setUp(() {
    backing = <String, String>{};
    TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      final args = (call.arguments as Map?)?.cast<String, dynamic>() ?? {};
      final key = args['key'] as String?;
      switch (call.method) {
        case 'write':
          if (key != null) backing[key] = args['value'] as String? ?? '';
          return null;
        case 'read':
          return key == null ? null : backing[key];
        case 'delete':
          if (key != null) backing.remove(key);
          return null;
        case 'readAll':
          return Map<String, String>.from(backing);
        case 'deleteAll':
          backing.clear();
          return null;
        case 'containsKey':
          return key != null && backing.containsKey(key);
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('AuthStorage', () {
    test('save persists access and refresh under correct keys', () async {
      final s = AuthStorage(storage: const FlutterSecureStorage());
      await s.save(access: 'A.JWT', refresh: 'R.OPAQUE');

      expect(backing[AppConstants.storageAccessTokenKey], 'A.JWT');
      expect(backing[AppConstants.storageRefreshTokenKey], 'R.OPAQUE');
    });

    test('readAccess and readRefresh return saved values', () async {
      final s = AuthStorage(storage: const FlutterSecureStorage());
      await s.save(access: 'A1', refresh: 'R1');

      expect(await s.readAccess(), 'A1');
      expect(await s.readRefresh(), 'R1');
    });

    test('readAccess returns null when nothing stored', () async {
      final s = AuthStorage(storage: const FlutterSecureStorage());
      expect(await s.readAccess(), isNull);
      expect(await s.readRefresh(), isNull);
    });

    test('clear deletes both tokens', () async {
      final s = AuthStorage(storage: const FlutterSecureStorage());
      await s.save(access: 'A', refresh: 'R');
      await s.clear();

      expect(await s.readAccess(), isNull);
      expect(await s.readRefresh(), isNull);
      expect(backing.containsKey(AppConstants.storageAccessTokenKey), false);
      expect(backing.containsKey(AppConstants.storageRefreshTokenKey), false);
    });

    test('hasAccess reflects presence', () async {
      final s = AuthStorage(storage: const FlutterSecureStorage());
      expect(await s.hasAccess(), false);

      await s.save(access: 'A', refresh: 'R');
      expect(await s.hasAccess(), true);

      await s.clear();
      expect(await s.hasAccess(), false);
    });
  });
}
```

- [ ] **Step 2: Run the tests**

Run: `flutter test test/auth/auth_storage_test.dart -r expanded`
Expected: 5 tests, all PASS.

- [ ] **Step 3: Run the full suite to make sure nothing else broke**

Run: `flutter test`
Expected: all existing tests still pass.

- [ ] **Step 4: Commit**

```bash
git add test/auth/auth_storage_test.dart
git commit -m "test(auth): cover AuthStorage save/read/clear with mock channel"
```

---

## End-of-chunk verification

- [ ] `flutter analyze` clean.
- [ ] `flutter test` all green.
- [ ] `git log --oneline` shows 5 new commits.
- [ ] Old auth still works: `flutter run` and verify cookie-based login (Google/Discord) still completes and you can see the dashboard. (This is a sanity check that none of the additive changes broke the existing flow.)

If all four boxes tick, proceed to [Chunk 2 — Auth Core](02-auth-core.md).
