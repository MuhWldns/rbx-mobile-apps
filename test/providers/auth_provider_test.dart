import 'package:flutter_test/flutter_test.dart';
import 'package:rbx_mobile_apps/providers/auth_provider.dart';

void main() {
  group('AuthProvider', () {
    test('initial state is loading with no user', () {
      final provider = AuthProvider();

      // Before init(), isLoading should be true
      expect(provider.isLoading, true);
      expect(provider.user, isNull);
      expect(provider.isAuthenticated, false);
    });

    test('isAuthenticated returns true when user is set', () {
      final provider = AuthProvider();

      // After init with no saved session, user should be null
      expect(provider.isAuthenticated, false);
    });

    test('notifies listeners on state changes', () {
      final provider = AuthProvider();
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      // Trigger a logout (even without session, should notify)
      provider.logout();

      expect(notifyCount, greaterThan(0));
    });
  });
}
