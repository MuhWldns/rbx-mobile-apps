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
    // ignore: avoid_print
    print('[AuthService] opening OAuth URL: $url');
    try {
      final result = await _webAuth.authenticate(
        url: url,
        callbackUrlScheme: AppConstants.oauthCallbackScheme,
      );
      // ignore: avoid_print
      print('[AuthService] callback result: $result');
      final uri = Uri.parse(result);
      if (uri.queryParameters['error'] != null) {
        // ignore: avoid_print
        print('[AuthService] callback error: ${uri.queryParameters['error']}');
        return false;
      }
      final access = uri.queryParameters['access'];
      final refresh = uri.queryParameters['refresh'];
      if (access == null || refresh == null) {
        // ignore: avoid_print
        print('[AuthService] missing tokens in callback (access=$access, refresh=$refresh)');
        return false;
      }
      await storage.save(access: access, refresh: refresh);
      return true;
    } catch (e, st) {
      // ignore: avoid_print
      print('[AuthService] login failed: $e\n$st');
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
