import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'constants.dart';

/// HTTP client that manages session cookies for API calls.
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _sessionCookie;

  /// Initialize by loading saved cookie from secure storage.
  Future<void> init() async {
    _sessionCookie = await _storage.read(key: AppConstants.storageCookieKey);
  }

  /// Save a session cookie (called after OAuth WebView extraction).
  Future<void> setSessionCookie(String cookie) async {
    _sessionCookie = cookie;
    await _storage.write(key: AppConstants.storageCookieKey, value: cookie);
  }

  /// Clear session cookie (logout).
  Future<void> clearSession() async {
    _sessionCookie = null;
    await _storage.delete(key: AppConstants.storageCookieKey);
  }

  /// Whether we have a session cookie stored.
  bool get hasSession => _sessionCookie != null && _sessionCookie!.isNotEmpty;

  /// Build headers with cookie.
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_sessionCookie != null) 'Cookie': _sessionCookie!,
      };

  /// GET request.
  Future<http.Response> get(String url) async {
    final response = await http.get(Uri.parse(url), headers: _headers);
    _extractSetCookie(response);
    return response;
  }

  /// POST request.
  Future<http.Response> post(String url, {Map<String, dynamic>? body}) async {
    final response = await http.post(
      Uri.parse(url),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    _extractSetCookie(response);
    return response;
  }

  /// PUT request.
  Future<http.Response> put(String url, {Map<String, dynamic>? body}) async {
    final response = await http.put(
      Uri.parse(url),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    _extractSetCookie(response);
    return response;
  }

  /// Extract and persist any set-cookie header from response.
  void _extractSetCookie(http.Response response) {
    final setCookie = response.headers['set-cookie'];
    if (setCookie != null && setCookie.contains(AppConstants.sessionCookieKey)) {
      // Parse the connect.sid value
      final match =
          RegExp(r'connect\.sid=([^;]+)').firstMatch(setCookie);
      if (match != null) {
        final cookieValue = '${AppConstants.sessionCookieKey}=${match.group(1)}';
        setSessionCookie(cookieValue);
      }
    }
  }
}
