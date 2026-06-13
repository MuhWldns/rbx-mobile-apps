import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rbx_mobile_apps/models/user.dart';
import 'package:rbx_mobile_apps/providers/auth_provider.dart';
import 'package:rbx_mobile_apps/pages/topup_page.dart';

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
    'email': 'test@example.com',
    'displayName': 'Test User',
    'fullName': 'Test User Full',
    'role': 'USER',
    'walletBalance': 50000,
    'totalTopUp': 100000,
    'totalSpent': 50000,
    'freeAudio': {
      'dateKey': '2026-06-08',
      'usedToday': 0,
      'dailyLimit': 3,
      'paidAudioCost': 2000,
    },
    'providers': ['DISCORD'],
  });
}

void main() {
  group('TopUpPage', () {
    testWidgets('shows header and balance', (tester) async {
      final provider = FakeAuthProvider(user: _createTestUser());

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: provider,
            child: const Scaffold(body: TopUpPage()),
          ),
        ),
      );

      expect(find.text('TOP UP'), findsOneWidget);
      expect(find.text('Isi saldo dengan QRIS'), findsOneWidget);
      expect(find.textContaining('50.000'), findsWidgets);
    });

    testWidgets('shows input form with quick amounts', (tester) async {
      final provider = FakeAuthProvider(user: _createTestUser());

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: provider,
            child: const Scaffold(body: TopUpPage()),
          ),
        ),
      );

      expect(find.text('Nominal top up'), findsOneWidget);
      expect(find.text('Pilih nominal'), findsOneWidget);
      expect(find.text('Lanjut ke QRIS'), findsOneWidget);

      // Quick amounts
      expect(find.textContaining('10.000'), findsWidgets);
      expect(find.textContaining('25.000'), findsWidgets);
      expect(find.textContaining('50.000'), findsWidgets);
      expect(find.textContaining('100.000'), findsWidgets);
      expect(find.textContaining('250.000'), findsWidgets);
      expect(find.textContaining('500.000'), findsWidgets);
    });

    testWidgets('shows error when amount is below minimum', (tester) async {
      final provider = FakeAuthProvider(user: _createTestUser());

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: provider,
            child: const Scaffold(body: TopUpPage()),
          ),
        ),
      );

      // Clear existing text and enter invalid amount
      final textField = find.byType(TextField);
      await tester.enterText(textField, '500');
      await tester.pump();

      // Tap submit
      await tester.tap(find.text('Lanjut ke QRIS'));
      await tester.pump();

      expect(find.text('Minimal top up Rp 1.000.'), findsOneWidget);
    });

    testWidgets('shows error when amount exceeds maximum', (tester) async {
      final provider = FakeAuthProvider(user: _createTestUser());

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: provider,
            child: const Scaffold(body: TopUpPage()),
          ),
        ),
      );

      final textField = find.byType(TextField);
      await tester.enterText(textField, '600000');
      await tester.pump();

      await tester.tap(find.text('Lanjut ke QRIS'));
      await tester.pump();

      expect(find.text('Maksimal QRIS Rp 500.000.'), findsOneWidget);
    });

    testWidgets('shows loading when user is null', (tester) async {
      final provider = FakeAuthProvider(user: null);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: provider,
            child: const Scaffold(body: TopUpPage()),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
