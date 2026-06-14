import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rbx_mobile_apps/auth/auth_service.dart';
import 'package:rbx_mobile_apps/models/user.dart';
import 'package:rbx_mobile_apps/providers/auth_provider.dart';
import 'package:rbx_mobile_apps/services/user_service.dart';
import 'package:rbx_mobile_apps/pages/login_page.dart';

class FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  User? _user;
  bool _isLoading;

  FakeAuthProvider({User? user, bool isLoading = false})
      : _user = user,
        _isLoading = isLoading;

  @override
  User? get user => _user;

  @override
  bool get isLoading => _isLoading;

  @override
  bool get isAuthenticated => _user != null;

  @override
  AuthService get authService => throw UnimplementedError();

  @override
  UserService get userService => throw UnimplementedError();

  @override
  Future<void> init() async {}

  @override
  Future<bool> loginWithGoogle() async => true;

  @override
  Future<bool> loginWithDiscord() async => true;

  @override
  Future<void> refreshUser() async {}

  @override
  Future<void> logout() async {
    _user = null;
    notifyListeners();
  }
}

void main() {
  group('LoginPage', () {
    testWidgets('renders login UI elements', (tester) async {
      final authProvider = FakeAuthProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: authProvider,
            child: const LoginPage(),
          ),
        ),
      );

      expect(find.text('LOGIN'), findsOneWidget);
      expect(find.text('Sign in to continue'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Continue with Discord'), findsOneWidget);
      expect(find.text('What happens after login'), findsOneWidget);
    });

    testWidgets('shows description text', (tester) async {
      final authProvider = FakeAuthProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: authProvider,
            child: const LoginPage(),
          ),
        ),
      );

      expect(
        find.text(
          'Use Google or Discord to access your dashboard, wallet, and licenses.',
        ),
        findsOneWidget,
      );
    });
  });
}
