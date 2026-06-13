import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rbx_mobile_apps/providers/auth_provider.dart';
import 'package:rbx_mobile_apps/pages/login_page.dart';

void main() {
  group('LoginPage', () {
    testWidgets('renders login UI elements', (tester) async {
      final authProvider = AuthProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: authProvider,
            child: const LoginPage(),
          ),
        ),
      );

      // Header text
      expect(find.text('LOGIN'), findsOneWidget);
      expect(find.text('Sign in to continue'), findsOneWidget);

      // OAuth buttons
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Continue with Discord'), findsOneWidget);

      // Info box
      expect(find.text('What happens after login'), findsOneWidget);
    });

    testWidgets('shows description text', (tester) async {
      final authProvider = AuthProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
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
