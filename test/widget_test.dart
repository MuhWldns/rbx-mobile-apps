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
      expect(AppConstants.authRefresh, 'https://api-rbx.muhwldns.me/auth/refresh');
      expect(AppConstants.authLogoutMobile, 'https://api-rbx.muhwldns.me/auth/logout-mobile');
    });

    test('topupStatus generates correct URL', () {
      expect(
        AppConstants.topupStatus('order123'),
        'https://api-rbx.muhwldns.me/topup/status/order123',
      );
    });

    test('OAuth deep-link scheme is rbxroyale', () {
      expect(AppConstants.oauthCallbackScheme, 'rbxroyale');
      expect(AppConstants.oauthMobileQueryParam, '?platform=mobile');
    });

    test('storage keys are stable', () {
      expect(AppConstants.storageAccessTokenKey, 'auth_access_token');
      expect(AppConstants.storageRefreshTokenKey, 'auth_refresh_token');
    });
  });
}
