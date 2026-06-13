import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rbx_mobile_apps/models/user.dart';
import 'package:rbx_mobile_apps/providers/auth_provider.dart';
import 'package:rbx_mobile_apps/pages/dashboard_page.dart';

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

User _createTestUser() {
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
    'robloxUserId': '123456789',
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
  group('DashboardPage', () {
    testWidgets('shows greeting with user display name', (tester) async {
      final provider = FakeAuthProvider(user: _createTestUser());

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: provider,
            child: const Scaffold(body: DashboardPage()),
          ),
        ),
      );

      expect(find.text('Halo, Test User!'), findsOneWidget);
      expect(find.text('Selamat datang kembali di RBX Royale.'), findsOneWidget);
    });

    testWidgets('shows wallet balance formatted in Rupiah', (tester) async {
      final provider = FakeAuthProvider(user: _createTestUser());

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: provider,
            child: const Scaffold(body: DashboardPage()),
          ),
        ),
      );

      // Wallet balance: Rp 75.000
      expect(find.textContaining('75.000'), findsWidgets);
    });

    testWidgets('shows audio quota', (tester) async {
      final provider = FakeAuthProvider(user: _createTestUser());

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: provider,
            child: const Scaffold(body: DashboardPage()),
          ),
        ),
      );

      expect(find.text('Audio Quota'), findsOneWidget);
      expect(find.text('Free audio hari ini'), findsOneWidget);
    });

    testWidgets('shows quick action buttons', (tester) async {
      final provider = FakeAuthProvider(user: _createTestUser());

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: provider,
            child: const Scaffold(body: DashboardPage()),
          ),
        ),
      );

      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('Top Up'), findsWidgets); // In quick actions + wallet card
      expect(find.text('Profile'), findsWidgets); // In card + quick actions
    });

    testWidgets('shows loading when user is null', (tester) async {
      final provider = FakeAuthProvider(user: null);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: provider,
            child: const Scaffold(body: DashboardPage()),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
