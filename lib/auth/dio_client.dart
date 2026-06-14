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
