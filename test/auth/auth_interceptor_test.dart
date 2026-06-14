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
      final dio = Dio(BaseOptions(
        baseUrl: 'https://api-rbx.muhwldns.me',
        // Default validateStatus: throw on 4xx so onError fires for the first 401.
      ));
      dio.httpClientAdapter = adapter;
      dio.interceptors.add(AuthInterceptor(storage: storage, auth: auth, dio: dio));

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
      final dio = Dio(BaseOptions(baseUrl: 'https://api-rbx.muhwldns.me'));
      dio.httpClientAdapter = adapter;
      dio.interceptors.add(AuthInterceptor(storage: storage, auth: auth, dio: dio));

      try {
        await dio.get<dynamic>('/topup/create');
        fail('expected DioException');
      } on DioException catch (e) {
        expect(e.response?.statusCode, 401);
      }
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
