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
