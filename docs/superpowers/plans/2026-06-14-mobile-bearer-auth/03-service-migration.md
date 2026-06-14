# Chunk 3 — Service Migration

> Part of [Mobile Bearer-Auth Migration](../2026-06-14-mobile-bearer-auth.md). Execute chunks in order. Requires chunks 1 and 2 complete.

**Goal of this chunk:** Migrate every HTTP service from the old `ApiClient` (cookie-based, `package:http`) to the new shared `Dio` instance with `AuthInterceptor`. Split `AuthService` (the legacy class) responsibilities: token-lifecycle stays in `lib/auth/auth_service.dart` (built in chunk 2), and the user-data calls (`/auth/me`, `/user/roblox-id`) move into a new `UserService`. Delete the old `lib/core/http_client.dart` and `lib/services/auth_service.dart`.

**Build state warning:** This chunk leaves the project temporarily failing analysis — `AuthProvider` and `LoginPage` still reference deleted symbols. Chunk 4's first task fixes that. Don't push to `main` between chunks 3 and 4.

**Files touched:**
- Modify: `lib/services/topup_service.dart`
- Modify: `lib/services/license_service.dart`
- Create: `lib/services/user_service.dart`
- Delete: `lib/core/http_client.dart`
- Delete: `lib/services/auth_service.dart`
- Modify: `test/services/topup_service_test.dart` (no behavior change — only imports if any)
- Modify: `test/services/license_service_test.dart` (same)
- Create: `test/services/user_service_test.dart`

---

## Task 3.1: Migrate `TopUpService` to Dio

**Files:**
- Modify: `lib/services/topup_service.dart`

The new service takes a `Dio` via constructor. Models (`TopUpResult`, `TopUpStatus`) and the public method names (`createTopUp`, `getStatus`) stay identical so `TopUpPage` keeps compiling.

- [ ] **Step 1: Replace the file**

Overwrite `lib/services/topup_service.dart` with:

```dart
import 'package:dio/dio.dart';

import '../core/constants.dart';

class TopUpResult {
  final String orderId;
  final String? publicId;
  final int amount;
  final String? paymentUrl;
  final String? qrisImageUrl;
  final String? expiresAt;

  TopUpResult({
    required this.orderId,
    this.publicId,
    required this.amount,
    this.paymentUrl,
    this.qrisImageUrl,
    this.expiresAt,
  });

  factory TopUpResult.fromJson(Map<String, dynamic> json) {
    return TopUpResult(
      orderId: json['orderId'] ?? '',
      publicId: json['publicId'],
      amount: json['amount'] ?? 0,
      paymentUrl: json['paymentUrl'],
      qrisImageUrl: json['qrisImageUrl'],
      expiresAt: json['expiresAt'],
    );
  }
}

class TopUpStatus {
  final bool paid;
  final String status;
  final int amount;
  final int? finalAmount;

  TopUpStatus({
    required this.paid,
    required this.status,
    required this.amount,
    this.finalAmount,
  });

  factory TopUpStatus.fromJson(Map<String, dynamic> json) {
    return TopUpStatus(
      paid: json['paid'] ?? false,
      status: json['status'] ?? 'PENDING',
      amount: json['amount'] ?? 0,
      finalAmount: json['finalAmount'],
    );
  }
}

class TopUpService {
  TopUpService({required this.dio});

  final Dio dio;

  Future<TopUpResult> createTopUp({
    required int amount,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
  }) async {
    final body = <String, dynamic>{'amount': amount};
    if (customerName != null) body['customer_name'] = customerName;
    if (customerEmail != null) body['customer_email'] = customerEmail;
    if (customerPhone != null) body['customer_phone'] = customerPhone;

    final res = await dio.post<Map<String, dynamic>>(
      AppConstants.topupCreate,
      data: body,
    );
    final data = res.data ?? const <String, dynamic>{};
    if (res.statusCode != 201) {
      throw Exception(data['error'] ?? 'Gagal membuat pembayaran');
    }
    return TopUpResult.fromJson(data);
  }

  Future<TopUpStatus> getStatus(String reference) async {
    final res = await dio.get<Map<String, dynamic>>(
      AppConstants.topupStatus(reference),
    );
    final data = res.data ?? const <String, dynamic>{};
    if (res.statusCode != 200) {
      throw Exception(data['error'] ?? 'Gagal mengecek status');
    }
    return TopUpStatus.fromJson(data);
  }
}
```

- [ ] **Step 2: Run the existing TopUp model tests (model behavior unchanged)**

Run: `flutter test test/services/topup_service_test.dart -r expanded`
Expected: all tests PASS (they only test the JSON parsing, which is identical).

- [ ] **Step 3: Commit**

```bash
git add lib/services/topup_service.dart
git commit -m "refactor(topup): migrate TopUpService to Dio + injected dio dep"
```

---

## Task 3.2: Migrate `LicenseService` to Dio

**Files:**
- Modify: `lib/services/license_service.dart`

- [ ] **Step 1: Replace the file**

Overwrite `lib/services/license_service.dart` with:

```dart
import 'package:dio/dio.dart';

import '../core/constants.dart';

class License {
  final String id;
  final String? publicId;
  final String? productName;
  final String licenseKey;
  final String licenseType;
  final String status;
  final int maxGames;
  final int whitelistedGames;
  final String? createdAt;

  License({
    required this.id,
    this.publicId,
    this.productName,
    required this.licenseKey,
    required this.licenseType,
    required this.status,
    required this.maxGames,
    required this.whitelistedGames,
    this.createdAt,
  });

  factory License.fromJson(Map<String, dynamic> json) {
    return License(
      id: json['id'] ?? '',
      publicId: json['publicId'],
      productName: json['product']?['name'] ?? json['productName'],
      licenseKey: json['licenseKey'] ?? '',
      licenseType: json['licenseType'] ?? 'PERSONAL',
      status: json['status'] ?? 'ACTIVE',
      maxGames: json['maxGames'] ?? 3,
      whitelistedGames: (json['gameWhitelists'] as List?)?.length ??
          (json['games'] as List?)?.length ??
          0,
      createdAt: json['createdAt'],
    );
  }
}

class LicenseService {
  LicenseService({required this.dio});

  final Dio dio;

  Future<List<License>> fetchLicenses() async {
    final res = await dio.get<Map<String, dynamic>>(AppConstants.licenses);
    final data = res.data ?? const <String, dynamic>{};
    if (res.statusCode != 200) {
      throw Exception(data['error'] ?? 'Gagal memuat licenses');
    }
    final list = data['licenses'] as List? ?? [];
    return list
        .map((l) => License.fromJson(l as Map<String, dynamic>))
        .toList();
  }
}
```

- [ ] **Step 2: Run existing license tests**

Run: `flutter test test/services/license_service_test.dart -r expanded`
Expected: model-parsing tests PASS.

- [ ] **Step 3: Commit**

```bash
git add lib/services/license_service.dart
git commit -m "refactor(license): migrate LicenseService to Dio + injected dio dep"
```

---

## Task 3.3: Create `UserService` (replaces non-auth methods of old AuthService)

**Files:**
- Create: `lib/services/user_service.dart`

`UserService` owns `/auth/me` and `/user/roblox-id`. The lifecycle methods (`logout`, OAuth) live in `lib/auth/auth_service.dart` from chunk 2.

- [ ] **Step 1: Write the file**

Create `lib/services/user_service.dart`:

```dart
import 'package:dio/dio.dart';

import '../core/constants.dart';
import '../models/user.dart';

class UserService {
  UserService({required this.dio});

  final Dio dio;

  /// Fetch current authenticated user. Returns null if backend says
  /// `{user: null}` or any non-200 response.
  Future<User?> fetchMe() async {
    try {
      final res = await dio.get<Map<String, dynamic>>(AppConstants.authMe);
      if (res.statusCode != 200) return null;
      final data = res.data;
      final raw = data?['user'];
      if (raw is Map<String, dynamic>) {
        return User.fromJson(raw);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Bind a Roblox user id to the current account. Throws on non-200.
  Future<Map<String, String>> saveRobloxId(String robloxUserId) async {
    final res = await dio.put<Map<String, dynamic>>(
      AppConstants.userRobloxId,
      data: {'robloxUserId': robloxUserId},
    );
    final data = res.data ?? const <String, dynamic>{};
    if (res.statusCode != 200) {
      throw Exception(data['error'] ?? 'Gagal menyimpan Roblox ID');
    }
    return {
      'username': (data['robloxUsername'] as String?) ?? '',
      'displayName': (data['robloxDisplayName'] as String?) ?? '',
    };
  }
}
```

- [ ] **Step 2: Verify analyze (only for the new file — old broken refs still there)**

Run: `flutter analyze lib/services/user_service.dart`
Expected: "No issues found!" for that file.

- [ ] **Step 3: Commit**

```bash
git add lib/services/user_service.dart
git commit -m "feat(user): add UserService for /auth/me and /user/roblox-id"
```

---

## Task 3.4: Delete the old `ApiClient` and old `AuthService`

**Files:**
- Delete: `lib/core/http_client.dart`
- Delete: `lib/services/auth_service.dart`

These two files reference `package:http` and the cookie storage flow. Nothing on the new path needs them. Deletions are safe at the file level — the broken imports they cause in `auth_provider.dart`, `profile_page.dart`, and `login_page.dart` are fixed in chunk 4 (and `analyze` will fail in between, which is expected).

- [ ] **Step 1: Remove the files**

Run from repo root:

```bash
rm lib/core/http_client.dart lib/services/auth_service.dart
```

- [ ] **Step 2: Verify analyze fails ONLY at the expected sites**

Run: `flutter analyze`
Expected: errors should be limited to:
- `lib/providers/auth_provider.dart` — import of `../services/auth_service.dart` and references to `AuthService`/`ApiClient`
- `lib/pages/profile_page.dart` — import of `../services/auth_service.dart` and `AuthService` usage
- `lib/pages/login_page.dart` — `AuthWebView` push (still chunk 4 territory) — this part won't surface from the deletes specifically; flag if it does

If there are errors in any other file, stop and re-check — services migrated in 3.1/3.2/3.3 should not depend on the deleted files.

- [ ] **Step 3: Commit**

```bash
git add -A lib/core/http_client.dart lib/services/auth_service.dart
git commit -m "refactor: delete legacy ApiClient and cookie-based AuthService"
```

---

## Task 3.5: Test `UserService`

**Files:**
- Create: `test/services/user_service_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/services/user_service_test.dart`:

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rbx_mobile_apps/services/user_service.dart';

class _CannedAdapter implements HttpClientAdapter {
  _CannedAdapter(this.handler);
  final Future<ResponseBody> Function(RequestOptions) handler;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int status, Object body) {
  return ResponseBody.fromBytes(
    utf8.encode(jsonEncode(body)),
    status,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );
}

Dio _buildDio(_CannedAdapter adapter) {
  return Dio(BaseOptions(
    baseUrl: 'https://api-rbx.muhwldns.me',
    validateStatus: (s) => s != null && s < 500,
  ))
    ..httpClientAdapter = adapter;
}

void main() {
  group('UserService.fetchMe', () {
    test('returns User on 200 with non-null user', () async {
      final adapter = _CannedAdapter((_) async => _json(200, {
            'user': {
              'id': 'u1',
              'email': 'a@b.com',
              'displayName': 'Alice',
              'role': 'USER',
              'walletBalance': 1000,
              'totalTopUp': 5000,
              'totalSpent': 4000,
              'providers': ['GOOGLE'],
            }
          }));
      final svc = UserService(dio: _buildDio(adapter));

      final user = await svc.fetchMe();

      expect(user, isNotNull);
      expect(user!.id, 'u1');
      expect(user.email, 'a@b.com');
      expect(user.walletBalance, 1000);
    });

    test('returns null when backend returns {user: null}', () async {
      final adapter = _CannedAdapter((_) async => _json(200, {'user': null}));
      final svc = UserService(dio: _buildDio(adapter));

      expect(await svc.fetchMe(), isNull);
    });

    test('returns null on non-200 response', () async {
      final adapter = _CannedAdapter((_) async => _json(401, {'error': 'invalid_token'}));
      final svc = UserService(dio: _buildDio(adapter));

      expect(await svc.fetchMe(), isNull);
    });
  });

  group('UserService.saveRobloxId', () {
    test('returns username + displayName on 200', () async {
      final adapter = _CannedAdapter((_) async => _json(200, {
            'ok': true,
            'robloxUserId': '123',
            'robloxUsername': 'builderman',
            'robloxDisplayName': 'Builderman',
          }));
      final svc = UserService(dio: _buildDio(adapter));

      final result = await svc.saveRobloxId('123');

      expect(result['username'], 'builderman');
      expect(result['displayName'], 'Builderman');
    });

    test('throws with backend error message on non-200', () async {
      final adapter = _CannedAdapter((_) async => _json(404, {
            'error': 'Roblox User ID not found. Please check your ID.',
          }));
      final svc = UserService(dio: _buildDio(adapter));

      expect(
        () => svc.saveRobloxId('999'),
        throwsA(predicate((e) =>
            e is Exception &&
            e.toString().contains('Roblox User ID not found'))),
      );
    });
  });
}
```

- [ ] **Step 2: Run the tests**

Run: `flutter test test/services/user_service_test.dart -r expanded`
Expected: 5 tests, all PASS.

- [ ] **Step 3: Commit**

```bash
git add test/services/user_service_test.dart
git commit -m "test(user): cover UserService fetchMe and saveRobloxId"
```

---

## End-of-chunk verification

- [ ] `flutter analyze` STILL HAS errors — only at: `lib/providers/auth_provider.dart`, `lib/pages/profile_page.dart`, and possibly `lib/pages/login_page.dart`. Anything else means a service still leaks the deleted symbols.
- [ ] Service unit tests pass: `flutter test test/services/ test/auth/` should be green.
- [ ] `git log --oneline` shows 5 new commits in this chunk.
- [ ] Do NOT push to `main` yet. Chunk 4 closes the analyze window.

Proceed immediately to [Chunk 4 — UI Integration](04-ui-integration.md).
