import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rbx_mobile_apps/models/user.dart';
import 'package:rbx_mobile_apps/providers/auth_provider.dart';
import 'package:rbx_mobile_apps/pages/profile_page.dart';

/// A testable AuthProvider with injectable user data.
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
  Future<void> init() async {}

  @override
  Future<bool> onSessionObtained(String cookie) async => true;

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

void main() {
  group('ProfilePage', () {
    testWidgets('shows account information', (tester) async {
      final provider = FakeAuthProvider(user: _createTestUser());

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: provider,
            child: const Scaffold(body: ProfilePage()),
          ),
        ),
      );

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

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: provider,
            child: const Scaffold(body: ProfilePage()),
          ),
        ),
      );

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

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: provider,
            child: const Scaffold(body: ProfilePage()),
          ),
        ),
      );

      expect(find.textContaining('Roblox ID tersambung: 987654321'), findsOneWidget);
    });

    testWidgets('shows wallet summary', (tester) async {
      final provider = FakeAuthProvider(user: _createTestUser());

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: provider,
            child: const Scaffold(body: ProfilePage()),
          ),
        ),
      );

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

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: provider,
            child: const Scaffold(body: ProfilePage()),
          ),
        ),
      );

      await tester.scrollUntilVisible(
        find.text('Logout'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Logout'), findsOneWidget);
    });

    testWidgets('shows loading when user is null', (tester) async {
      final provider = FakeAuthProvider(user: null);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: provider,
            child: const Scaffold(body: ProfilePage()),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
