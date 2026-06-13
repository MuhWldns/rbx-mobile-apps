import 'package:flutter_test/flutter_test.dart';
import 'package:rbx_mobile_apps/core/constants.dart';

void main() {
  group('AppConstants', () {
    test('API base URL is correct', () {
      expect(AppConstants.apiBaseUrl, 'https://api-rbx.muhwldns.me');
    });

    test('auth URLs use correct base', () {
      expect(AppConstants.authGoogle, 'https://api-rbx.muhwldns.me/auth/google');
      expect(AppConstants.authDiscord, 'https://api-rbx.muhwldns.me/auth/discord');
      expect(AppConstants.authMe, 'https://api-rbx.muhwldns.me/auth/me');
      expect(AppConstants.authLogout, 'https://api-rbx.muhwldns.me/auth/logout');
    });

    test('topupStatus generates correct URL', () {
      expect(
        AppConstants.topupStatus('order123'),
        'https://api-rbx.muhwldns.me/topup/status/order123',
      );
    });

    test('session cookie key is connect.sid', () {
      expect(AppConstants.sessionCookieKey, 'connect.sid');
    });
  });
}
