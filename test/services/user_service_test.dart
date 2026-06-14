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
