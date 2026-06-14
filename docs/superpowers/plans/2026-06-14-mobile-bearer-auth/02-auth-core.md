# Chunk 2 — Auth Core

> Part of [Mobile Bearer-Auth Migration](../2026-06-14-mobile-bearer-auth.md). Execute chunks in order. Requires chunk 1 complete.

**Goal of this chunk:** Build the `AuthService` (login/refresh/logout), the `AuthInterceptor` (auto-refresh on 401 token_expired), and a Dio factory. All new code, all unit-tested. Nothing is wired into the UI yet — `main.dart` still constructs the old cookie-based world.

**Files touched:**
- Create: `lib/auth/auth_service.dart`
- Create: `lib/auth/auth_interceptor.dart`
- Create: `lib/auth/dio_client.dart`
- Create: `test/auth/auth_service_test.dart`
- Create: `test/auth/auth_interceptor_test.dart`

---

## Task 2.1: Create `AuthService`

**Files:**
- Create: `lib/auth/auth_service.dart`

- [ ] **Step 1: Write the file**

Create `lib/auth/auth_service.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import '../core/constants.dart';
import 'auth_storage.dart';

/// Wraps the OAuth + token-refresh + logout flows for the mobile client.
///
/// Construction takes a [Dio] used ONLY for the auth endpoints
/// (`/auth/refresh`, `/auth/logout-mobile`). The interceptor lives on the
/// app-wide Dio (see `dio_client.dart`); this service must not loop through
/// it. Each auth-endpoint call sets `X-Skip-Auth-Interceptor: '1'` so even
/// if the same Dio instance is reused, the interceptor steps aside.
class AuthService {
  AuthService({
    required this.storage,
    required this.dio,
    FlutterWebAuth2Authenticator? webAuthenticator,
  }) : _webAuth = webAuthenticator ?? const _DefaultWebAuthenticator();

  final AuthStorage storage;
  final Dio dio;
  final FlutterWebAuth2Authenticator _webAuth;

  Future<bool> loginWithGoogle() => _oauthLogin(AppConstants.authGoogle);

  Future<bool> loginWithDiscord() => _oauthLogin(AppConstants.authDiscord);

  Future<bool> _oauthLogin(String baseEndpoint) async {
    final url = '$baseEndpoint${AppConstants.oauthMobileQueryParam}';
    try {
      final result = await _webAuth.authenticate(
        url: url,
        callbackUrlScheme: AppConstants.oauthCallbackScheme,
      );
      final uri = Uri.parse(result);
      if (uri.queryParameters['error'] != null) return false;
      final access = uri.queryParameters['access'];
      final refresh = uri.queryParameters['refresh'];
      if (access == null || refresh == null) return false;
      await storage.save(access: access, refresh: refresh);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Try to refresh the access token. Returns true on success, false otherwise.
  /// On `refresh_invalid` (token rotated/expired) wipes storage so callers
  /// know to send the user back to the login screen.
  Future<bool> refreshAccessToken() async {
    final refresh = await storage.readRefresh();
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final res = await dio.post<Map<String, dynamic>>(
        AppConstants.authRefresh,
        data: {'refresh': refresh},
        options: Options(
          headers: {'X-Skip-Auth-Interceptor': '1'},
        ),
      );
      final body = res.data;
      if (res.statusCode == 200 && body != null) {
        final newAccess = body['access'] as String?;
        final newRefresh = body['refresh'] as String?;
        if (newAccess == null || newRefresh == null) return false;
        await storage.save(access: newAccess, refresh: newRefresh);
        return true;
      }
      return false;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await storage.clear();
      }
      return false;
    }
  }

  Future<void> logout() async {
    final access = await storage.readAccess();
    final refresh = await storage.readRefresh();
    if (access != null && refresh != null) {
      try {
        await dio.post<dynamic>(
          AppConstants.authLogoutMobile,
          data: {'refresh': refresh},
          options: Options(
            headers: {
              'Authorization': 'Bearer $access',
              'X-Skip-Auth-Interceptor': '1',
            },
          ),
        );
      } catch (_) {
        // network failure is fine — local wipe is the source of truth
      }
    }
    await storage.clear();
  }

  Future<bool> isLoggedIn() => storage.hasAccess();
}

/// Indirection for `FlutterWebAuth2.authenticate` so tests can inject a fake.
abstract class FlutterWebAuth2Authenticator {
  Future<String> authenticate({
    required String url,
    required String callbackUrlScheme,
  });
}

class _DefaultWebAuthenticator implements FlutterWebAuth2Authenticator {
  const _DefaultWebAuthenticator();

  @override
  Future<String> authenticate({
    required String url,
    required String callbackUrlScheme,
  }) {
    return FlutterWebAuth2.authenticate(
      url: url,
      callbackUrlScheme: callbackUrlScheme,
    );
  }
}
```

- [ ] **Step 2: Verify analyze**

Run: `flutter analyze`
Expected: "No issues found!".

- [ ] **Step 3: Commit**

```bash
git add lib/auth/auth_service.dart
git commit -m "feat(auth): add AuthService for OAuth login + token refresh"
```

---

## Task 2.2: Create `AuthInterceptor`

**Files:**
- Create: `lib/auth/auth_interceptor.dart`

The interceptor does two jobs: (1) attach `Authorization: Bearer <access>` to outgoing requests unless the caller asks to skip; (2) on a 401 with `error: token_expired`, call `AuthService.refreshAccessToken()` and retry the original request once.

- [ ] **Step 1: Write the file**

Create `lib/auth/auth_interceptor.dart`:

```dart
import 'package:dio/dio.dart';

import 'auth_service.dart';
import 'auth_storage.dart';

/// Dio interceptor that attaches the Bearer access token to every request and
/// transparently refreshes + retries once on `token_expired` 401s.
///
/// Callers that must NOT be intercepted (the refresh and logout-mobile calls
/// inside [AuthService]) set the synthetic header `X-Skip-Auth-Interceptor: '1'`.
/// The interceptor strips that header before forwarding.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.storage,
    required this.auth,
    required this.dio,
  });

  final AuthStorage storage;
  final AuthService auth;
  final Dio dio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.headers['X-Skip-Auth-Interceptor'] == '1') {
      options.headers.remove('X-Skip-Auth-Interceptor');
      return handler.next(options);
    }
    final access = await storage.readAccess();
    if (access != null && access.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $access';
    }
    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    if (response?.statusCode != 401) return handler.next(err);

    final body = response?.data;
    final code = body is Map ? body['error'] : null;
    if (code != 'token_expired') return handler.next(err);

    final refreshed = await auth.refreshAccessToken();
    if (!refreshed) return handler.next(err);

    final newAccess = await storage.readAccess();
    if (newAccess == null || newAccess.isEmpty) return handler.next(err);

    final original = err.requestOptions;
    original.headers['Authorization'] = 'Bearer $newAccess';
    try {
      final retried = await dio.fetch<dynamic>(original);
      return handler.resolve(retried);
    } catch (_) {
      return handler.next(err);
    }
  }
}
```

- [ ] **Step 2: Verify analyze**

Run: `flutter analyze`
Expected: "No issues found!".

- [ ] **Step 3: Commit**

```bash
git add lib/auth/auth_interceptor.dart
git commit -m "feat(auth): add AuthInterceptor for bearer header + auto-refresh"
```

---

## Task 2.3: Create the Dio factory

**Files:**
- Create: `lib/auth/dio_client.dart`

A single function that builds a configured `Dio` and wires the interceptor. Centralizing this stops `main.dart` from owning the wiring detail and lets tests build their own pre-wired Dio.

- [ ] **Step 1: Write the file**

Create `lib/auth/dio_client.dart`:

```dart
import 'package:dio/dio.dart';

import '../core/constants.dart';
import 'auth_interceptor.dart';
import 'auth_service.dart';
import 'auth_storage.dart';

/// Build the app-wide [Dio] with [AuthInterceptor] attached.
///
/// Usage from `main.dart`:
/// ```dart
/// final storage = AuthStorage();
/// final dio = buildDioClient(storage: storage);
/// final auth = AuthService(storage: storage, dio: dio);
/// dio.interceptors.add(AuthInterceptor(storage: storage, auth: auth, dio: dio));
/// ```
///
/// Or use [buildAuthStack] to do all four lines at once.
Dio buildDioClient({Duration? connectTimeout, Duration? receiveTimeout}) {
  return Dio(
    BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: connectTimeout ?? const Duration(seconds: 15),
      receiveTimeout: receiveTimeout ?? const Duration(seconds: 30),
      contentType: 'application/json',
      // Don't throw on 4xx — services decode the body and surface
      // user-friendly errors themselves.
      validateStatus: (s) => s != null && s < 500,
    ),
  );
}

/// Convenience: build [Dio], [AuthService], wire the interceptor, return all
/// three. The returned [Dio] is the one services should use.
class AuthStack {
  AuthStack({required this.dio, required this.auth, required this.storage});

  final Dio dio;
  final AuthService auth;
  final AuthStorage storage;
}

AuthStack buildAuthStack({AuthStorage? storage}) {
  final s = storage ?? AuthStorage();
  final dio = buildDioClient();
  final auth = AuthService(storage: s, dio: dio);
  dio.interceptors.add(AuthInterceptor(storage: s, auth: auth, dio: dio));
  return AuthStack(dio: dio, auth: auth, storage: s);
}
```

- [ ] **Step 2: Verify analyze**

Run: `flutter analyze`
Expected: "No issues found!".

- [ ] **Step 3: Commit**

```bash
git add lib/auth/dio_client.dart
git commit -m "feat(auth): add Dio factory and AuthStack convenience builder"
```

---

## Task 2.4: Test `AuthService`

**Files:**
- Create: `test/auth/auth_service_test.dart`

We use Dio's built-in `MockAdapter` pattern via `dio.httpClientAdapter` replacement. Because Dio doesn't ship a mock adapter in the core package, we hand-roll a tiny `HttpClientAdapter` that records requests and returns canned responses.

- [ ] **Step 1: Write the failing test**

Create `test/auth/auth_service_test.dart`:

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rbx_mobile_apps/auth/auth_service.dart';
import 'package:rbx_mobile_apps/auth/auth_storage.dart';
import 'package:rbx_mobile_apps/core/constants.dart';

class _CannedAdapter implements HttpClientAdapter {
  _CannedAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;
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
  final bytes = utf8.encode(jsonEncode(body));
  return ResponseBody.fromBytes(
    bytes,
    status,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );
}

class _StubWebAuth implements FlutterWebAuth2Authenticator {
  _StubWebAuth(this.result);
  final String result;
  @override
  Future<String> authenticate({
    required String url,
    required String callbackUrlScheme,
  }) async =>
      result;
}

class _ThrowingWebAuth implements FlutterWebAuth2Authenticator {
  @override
  Future<String> authenticate({
    required String url,
    required String callbackUrlScheme,
  }) async =>
      throw Exception('user cancelled');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
        case 'deleteAll':
          backing.clear();
          return null;
        case 'readAll':
          return Map<String, String>.from(backing);
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

  AuthStorage newStorage() => AuthStorage(storage: const FlutterSecureStorage());

  group('AuthService.loginWithGoogle', () {
    test('saves tokens when callback URL has access+refresh', () async {
      final storage = newStorage();
      final dio = Dio();
      final svc = AuthService(
        storage: storage,
        dio: dio,
        webAuthenticator: _StubWebAuth('rbxroyale://auth?access=A.JWT&refresh=R'),
      );

      final ok = await svc.loginWithGoogle();

      expect(ok, true);
      expect(await storage.readAccess(), 'A.JWT');
      expect(await storage.readRefresh(), 'R');
    });

    test('returns false when callback has error', () async {
      final storage = newStorage();
      final svc = AuthService(
        storage: storage,
        dio: Dio(),
        webAuthenticator: _StubWebAuth('rbxroyale://auth?error=oauth_failed'),
      );

      final ok = await svc.loginWithGoogle();

      expect(ok, false);
      expect(await storage.readAccess(), isNull);
    });

    test('returns false when callback missing tokens', () async {
      final storage = newStorage();
      final svc = AuthService(
        storage: storage,
        dio: Dio(),
        webAuthenticator: _StubWebAuth('rbxroyale://auth?access=onlyaccess'),
      );

      expect(await svc.loginWithGoogle(), false);
    });

    test('returns false when web auth throws (user cancel)', () async {
      final storage = newStorage();
      final svc = AuthService(
        storage: storage,
        dio: Dio(),
        webAuthenticator: _ThrowingWebAuth(),
      );

      expect(await svc.loginWithGoogle(), false);
      expect(await storage.readAccess(), isNull);
    });
  });

  group('AuthService.refreshAccessToken', () {
    test('returns false when no refresh token stored', () async {
      final storage = newStorage();
      final svc = AuthService(
        storage: storage,
        dio: Dio(),
        webAuthenticator: _StubWebAuth(''),
      );

      expect(await svc.refreshAccessToken(), false);
    });

    test('persists new tokens on 200 and returns true', () async {
      final storage = newStorage();
      await storage.save(access: 'old.A', refresh: 'old.R');

      final adapter = _CannedAdapter((opts) async => _json(200, {
            'access': 'new.A',
            'refresh': 'new.R',
            'expiresIn': 604800,
          }));
      final dio = Dio()..httpClientAdapter = adapter;
      final svc = AuthService(
        storage: storage,
        dio: dio,
        webAuthenticator: _StubWebAuth(''),
      );

      final ok = await svc.refreshAccessToken();

      expect(ok, true);
      expect(await storage.readAccess(), 'new.A');
      expect(await storage.readRefresh(), 'new.R');
      expect(adapter.requests.single.path, AppConstants.authRefresh);
      expect(adapter.requests.single.headers['X-Skip-Auth-Interceptor'], '1');
    });

    test('wipes storage and returns false on 401 refresh_invalid', () async {
      final storage = newStorage();
      await storage.save(access: 'A', refresh: 'R');

      final dio = Dio()
        ..httpClientAdapter = _CannedAdapter(
          (_) async => _json(401, {'error': 'refresh_invalid'}),
        );
      // 401s with validateStatus default => DioException, which is what we want.
      dio.options.validateStatus = (s) => s != null && s < 400;
      final svc = AuthService(
        storage: storage,
        dio: dio,
        webAuthenticator: _StubWebAuth(''),
      );

      final ok = await svc.refreshAccessToken();

      expect(ok, false);
      expect(await storage.readAccess(), isNull);
      expect(await storage.readRefresh(), isNull);
    });
  });

  group('AuthService.logout', () {
    test('clears storage even when network call fails', () async {
      final storage = newStorage();
      await storage.save(access: 'A', refresh: 'R');

      final dio = Dio()
        ..httpClientAdapter = _CannedAdapter(
          (_) async => throw DioException(
            requestOptions: RequestOptions(path: '/'),
            type: DioExceptionType.connectionError,
          ),
        );
      final svc = AuthService(
        storage: storage,
        dio: dio,
        webAuthenticator: _StubWebAuth(''),
      );

      await svc.logout();

      expect(await storage.readAccess(), isNull);
      expect(await storage.readRefresh(), isNull);
    });

    test('skips network call when no tokens are stored', () async {
      final storage = newStorage();
      final adapter = _CannedAdapter((_) async => _json(200, {'ok': true}));
      final dio = Dio()..httpClientAdapter = adapter;
      final svc = AuthService(
        storage: storage,
        dio: dio,
        webAuthenticator: _StubWebAuth(''),
      );

      await svc.logout();

      expect(adapter.requests, isEmpty);
    });
  });

  group('AuthService.isLoggedIn', () {
    test('false when no token, true once saved', () async {
      final storage = newStorage();
      final svc = AuthService(
        storage: storage,
        dio: Dio(),
        webAuthenticator: _StubWebAuth(''),
      );
      expect(await svc.isLoggedIn(), false);

      await storage.save(access: 'A', refresh: 'R');
      expect(await svc.isLoggedIn(), true);
    });
  });
}
```

- [ ] **Step 2: Run the tests**

Run: `flutter test test/auth/auth_service_test.dart -r expanded`
Expected: all tests PASS.

- [ ] **Step 3: Commit**

```bash
git add test/auth/auth_service_test.dart
git commit -m "test(auth): cover AuthService login, refresh, logout, isLoggedIn"
```

---

## Task 2.5: Test `AuthInterceptor`

**Files:**
- Create: `test/auth/auth_interceptor_test.dart`

We exercise the interceptor against a Dio whose adapter we control. The first call returns `401 token_expired`; the second (the retry) returns `200 ok`. The fake `AuthService` we plug in just simulates a successful refresh by writing fresh tokens to storage.

- [ ] **Step 1: Write the failing test**

Create `test/auth/auth_interceptor_test.dart`:

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rbx_mobile_apps/auth/auth_interceptor.dart';
import 'package:rbx_mobile_apps/auth/auth_service.dart';
import 'package:rbx_mobile_apps/auth/auth_storage.dart';

class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this.responses);
  final List<ResponseBody Function(RequestOptions)> responses;
  final List<RequestOptions> requests = [];
  int _i = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final fn = responses[_i.clamp(0, responses.length - 1)];
    _i++;
    return fn(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int status, Object body) {
  final bytes = utf8.encode(jsonEncode(body));
  return ResponseBody.fromBytes(
    bytes,
    status,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );
}

class _FakeAuthService implements AuthService {
  _FakeAuthService(this._storage, {this.shouldSucceed = true});
  final AuthStorage _storage;
  final bool shouldSucceed;
  int refreshCalls = 0;

  @override
  AuthStorage get storage => _storage;

  @override
  Dio get dio => throw UnimplementedError();

  @override
  Future<bool> refreshAccessToken() async {
    refreshCalls++;
    if (!shouldSucceed) return false;
    await _storage.save(access: 'fresh.A', refresh: 'fresh.R');
    return true;
  }

  @override
  Future<bool> loginWithGoogle() => throw UnimplementedError();
  @override
  Future<bool> loginWithDiscord() => throw UnimplementedError();
  @override
  Future<void> logout() => throw UnimplementedError();
  @override
  Future<bool> isLoggedIn() => _storage.hasAccess();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
        case 'deleteAll':
          backing.clear();
          return null;
        case 'readAll':
          return Map<String, String>.from(backing);
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

  AuthStorage newStorage() => AuthStorage(storage: const FlutterSecureStorage());

  Dio buildDio(AuthStorage storage, AuthService auth, _ScriptedAdapter adapter) {
    final dio = Dio(BaseOptions(
      baseUrl: 'https://api-rbx.muhwldns.me',
      validateStatus: (s) => s != null && s < 500,
    ));
    dio.httpClientAdapter = adapter;
    dio.interceptors.add(AuthInterceptor(storage: storage, auth: auth, dio: dio));
    return dio;
  }

  group('AuthInterceptor.onRequest', () {
    test('attaches Bearer header when access token exists', () async {
      final storage = newStorage();
      await storage.save(access: 'A.JWT', refresh: 'R');
      final adapter = _ScriptedAdapter([(_) => _json(200, {'ok': true})]);
      final dio = buildDio(storage, _FakeAuthService(storage), adapter);

      await dio.get<dynamic>('/auth/me');

      expect(adapter.requests.single.headers['Authorization'], 'Bearer A.JWT');
    });

    test('omits Bearer header when no token stored', () async {
      final storage = newStorage();
      final adapter = _ScriptedAdapter([(_) => _json(200, {'ok': true})]);
      final dio = buildDio(storage, _FakeAuthService(storage), adapter);

      await dio.get<dynamic>('/auth/me');

      expect(adapter.requests.single.headers.containsKey('Authorization'), false);
    });

    test('strips X-Skip-Auth-Interceptor and skips bearer attach', () async {
      final storage = newStorage();
      await storage.save(access: 'A.JWT', refresh: 'R');
      final adapter = _ScriptedAdapter([(_) => _json(200, {'ok': true})]);
      final dio = buildDio(storage, _FakeAuthService(storage), adapter);

      await dio.post<dynamic>(
        '/auth/refresh',
        options: Options(headers: {'X-Skip-Auth-Interceptor': '1'}),
      );

      expect(adapter.requests.single.headers.containsKey('Authorization'), false);
      expect(adapter.requests.single.headers.containsKey('X-Skip-Auth-Interceptor'), false);
    });
  });

  group('AuthInterceptor.onError', () {
    test('refreshes and retries on 401 token_expired', () async {
      final storage = newStorage();
      await storage.save(access: 'old.A', refresh: 'old.R');
      final adapter = _ScriptedAdapter([
        (_) => _json(401, {'error': 'token_expired'}),
        (_) => _json(200, {'ok': true, 'user': {'id': '1'}}),
      ]);
      final auth = _FakeAuthService(storage);
      final dio = buildDio(storage, auth, adapter);

      final res = await dio.get<dynamic>('/auth/me');

      expect(res.statusCode, 200);
      expect(auth.refreshCalls, 1);
      expect(adapter.requests.length, 2);
      expect(adapter.requests[1].headers['Authorization'], 'Bearer fresh.A');
    });

    test('does not retry on non-token_expired 401', () async {
      final storage = newStorage();
      await storage.save(access: 'A', refresh: 'R');
      final adapter = _ScriptedAdapter([
        (_) => _json(401, {'error': 'invalid_token'}),
      ]);
      final auth = _FakeAuthService(storage);
      final dio = buildDio(storage, auth, adapter);

      // validateStatus < 500 means the call returns instead of throwing.
      final res = await dio.get<dynamic>('/topup/create');

      expect(res.statusCode, 401);
      expect(auth.refreshCalls, 0);
      expect(adapter.requests.length, 1);
    });

    test('does not retry when refresh fails', () async {
      final storage = newStorage();
      await storage.save(access: 'A', refresh: 'R');
      final adapter = _ScriptedAdapter([
        (_) => _json(401, {'error': 'token_expired'}),
      ]);
      final auth = _FakeAuthService(storage, shouldSucceed: false);
      final dio = buildDio(storage, auth, adapter);

      final res = await dio.get<dynamic>('/topup/create');

      expect(res.statusCode, 401);
      expect(auth.refreshCalls, 1);
      expect(adapter.requests.length, 1);
    });

    test('passes through non-401 errors untouched', () async {
      final storage = newStorage();
      await storage.save(access: 'A', refresh: 'R');
      final adapter = _ScriptedAdapter([
        (_) => _json(402, {'error': 'Insufficient balance'}),
      ]);
      final auth = _FakeAuthService(storage);
      final dio = buildDio(storage, auth, adapter);

      final res = await dio.get<dynamic>('/topup/create');

      expect(res.statusCode, 402);
      expect(auth.refreshCalls, 0);
    });
  });
}
```

- [ ] **Step 2: Run the tests**

Run: `flutter test test/auth/auth_interceptor_test.dart -r expanded`
Expected: all tests PASS.

- [ ] **Step 3: Run the full suite**

Run: `flutter test`
Expected: all tests pass.

- [ ] **Step 4: Commit**

```bash
git add test/auth/auth_interceptor_test.dart
git commit -m "test(auth): cover AuthInterceptor bearer attach + auto-refresh retry"
```

---

## End-of-chunk verification

- [ ] `flutter analyze` clean.
- [ ] `flutter test` all green.
- [ ] `git log --oneline` shows 5 new commits in this chunk.
- [ ] Old cookie flow still works (manual sanity check via `flutter run`) — none of the new code is wired in yet, so the app behaves exactly like before chunk 2.

If all four boxes tick, proceed to [Chunk 3 — Service Migration](03-service-migration.md).
