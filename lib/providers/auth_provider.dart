import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../models/user.dart';
import '../services/user_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({required this.authService, required this.userService});

  final AuthService authService;
  final UserService userService;

  User? _user;
  bool _isLoading = true;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  /// Boot: if a token exists, try to fetch /auth/me. The interceptor will
  /// silently refresh on token_expired; we only land in the unauthenticated
  /// branch when the token chain is genuinely dead.
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    if (await authService.isLoggedIn()) {
      _user = await userService.fetchMe();
      // If fetchMe came back null, the token chain is dead — wipe it so the
      // router sends the user to /login.
      if (_user == null) {
        await authService.logout();
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> loginWithGoogle() async {
    final ok = await authService.loginWithGoogle();
    if (!ok) return false;
    _user = await userService.fetchMe();
    notifyListeners();
    return _user != null;
  }

  Future<bool> loginWithDiscord() async {
    final ok = await authService.loginWithDiscord();
    if (!ok) return false;
    _user = await userService.fetchMe();
    notifyListeners();
    return _user != null;
  }

  Future<void> refreshUser() async {
    _user = await userService.fetchMe();
    notifyListeners();
  }

  Future<void> logout() async {
    await authService.logout();
    _user = null;
    notifyListeners();
  }
}
