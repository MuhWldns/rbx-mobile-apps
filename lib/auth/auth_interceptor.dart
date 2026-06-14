import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

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
      debugPrint('[AuthInterceptor] ${options.method} ${options.path} '
          '(SKIP-AUTH)');
      return handler.next(options);
    }
    final access = await storage.readAccess();
    if (access != null && access.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $access';
      debugPrint('[AuthInterceptor] ${options.method} ${options.path} '
          'attached Bearer ${access.substring(0, access.length.clamp(0, 20))}...');
    } else {
      debugPrint('[AuthInterceptor] ${options.method} ${options.path} '
          '(no token)');
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
