import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../core/http_client.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiClient _apiClient = ApiClient();

  User? _user;
  bool _isLoading = true;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  /// Initialize: load saved session and try to fetch user.
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    await _apiClient.init();

    if (_apiClient.hasSession) {
      _user = await _authService.fetchMe();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Called after OAuth WebView extracts the session cookie.
  Future<bool> onSessionObtained(String cookie) async {
    await _apiClient.setSessionCookie(cookie);
    _user = await _authService.fetchMe();
    notifyListeners();
    return _user != null;
  }

  /// Refresh user data from the server.
  Future<void> refreshUser() async {
    _user = await _authService.fetchMe();
    notifyListeners();
  }

  /// Logout.
  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }
}
