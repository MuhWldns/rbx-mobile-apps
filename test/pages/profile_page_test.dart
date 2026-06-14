import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rbx_mobile_apps/auth/auth_service.dart';
import 'package:rbx_mobile_apps/models/user.dart';
import 'package:rbx_mobile_apps/providers/auth_provider.dart';
import 'package:rbx_mobile_apps/services/user_service.dart';
import 'package:rbx_mobile_apps/pages/profile_page.dart';

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

User _createTestUser({String? robloxUserId}) {
  return User.fromJson({
    'id': 'test-user-id',
    'publicId': 'ACC-IDN-2606-000001',
    'email': 'test@example.com',
    'displayName': 'Test User',
    'fullName': 'Test User Full',
    'avatarUrl': null,
    'lastLoginAt': '2026-06-01T00:00:00.000Z',
    'lastLoginProvider': 'DISCORD',
    'role': 'USER',
    'walletBalance': 75000,
    'totalTopUp': 100000,
    'totalSpent': 25000,
    'robloxUserId': robloxUserId,
    'freeAudio': {
      'dateKey': '2026-06-08',
      'usedToday': 1,
      'dailyLimit': 3,
      'paidAudioCost': 2000,
    },
    'providers': ['DISCORD'],
  });
}

Widget _wrap(Widget child, {required FakeAuthProvider provider}) {
  final dio = Dio();
  return MaterialApp(
    home: MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: provider),
        Provider<UserService>.value(value: UserService(dio: dio)),
      ],
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  group('ProfilePage', () {
    testWidgets('shows account information', (tester) async {
      final provider = FakeAuthProvider(user: _createTestUser());

      await tester.pumpWidget(_wrap(const ProfilePage(), provider: provider));

      expect(find.text('PROFILE'), findsOneWidget);
      expect(find.text('Account Settings'), findsOneWidget);
      expect(find.text('Account Information'), findsOneWidget);
      expect(find.text('ACC-IDN-2606-000001'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('Test User'), findsWidgets);
      expect(find.text('DISCORD'), findsOneWidget);
      expect(find.text('USER'), findsOneWidget);
    });

    testWidgets('shows Roblox section', (tester) async {
      final provider = FakeAuthProvider(user: _createTestUser());

      await tester.pumpWidget(_wrap(const ProfilePage(), provider: provider));

      await tester.scrollUntilVisible(
        find.text('Roblox Account'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Roblox Account'), findsOneWidget);
      expect(find.text('Roblox User ID'), findsOneWidget);
    });

    testWidgets('shows connected status when robloxUserId exists', (tester) async {
      final provider = FakeAuthProvider(
        user: _createTestUser(robloxUserId: '987654321'),
      );

      await tester.pumpWidget(_wrap(const ProfilePage(), provider: provider));

      expect(find.textContaining('Roblox ID tersambung: 987654321'), findsOneWidget);
    });

    testWidgets('shows wallet summary', (tester) async {
      final provider = FakeAuthProvider(user: _createTestUser());

      await tester.pumpWidget(_wrap(const ProfilePage(), provider: provider));

      await tester.scrollUntilVisible(
        find.text('Wallet'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Wallet'), findsOneWidget);
      expect(find.textContaining('75.000'), findsWidgets);
      expect(find.textContaining('100.000'), findsWidgets);
      expect(find.textContaining('25.000'), findsWidgets);
    });

    testWidgets('shows logout button', (tester) async {
      final provider = FakeAuthProvider(user: _createTestUser());

      await tester.pumpWidget(_wrap(const ProfilePage(), provider: provider));

      await tester.scrollUntilVisible(
        find.text('Logout'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Logout'), findsOneWidget);
    });

    testWidgets('shows loading when user is null', (tester) async {
      final provider = FakeAuthProvider(user: null);

      await tester.pumpWidget(_wrap(const ProfilePage(), provider: provider));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
