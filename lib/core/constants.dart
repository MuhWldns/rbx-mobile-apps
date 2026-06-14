class AppConstants {
  AppConstants._();

  static const String apiBaseUrl = 'https://api-rbx.muhwldns.me';
  static const String authGoogle = '$apiBaseUrl/auth/google';
  static const String authDiscord = '$apiBaseUrl/auth/discord';
  static const String authMe = '$apiBaseUrl/auth/me';
  static const String authLogout = '$apiBaseUrl/auth/logout';
  static const String authRefresh = '$apiBaseUrl/auth/refresh';
  static const String authLogoutMobile = '$apiBaseUrl/auth/logout-mobile';
  static const String userRobloxId = '$apiBaseUrl/user/roblox-id';
  static const String topupCreate = '$apiBaseUrl/topup/create';
  static String topupStatus(String reference) =>
      '$apiBaseUrl/topup/status/$reference';
  static const String licenses = '$apiBaseUrl/licenses';

  // Storage keys
  static const String storageAccessTokenKey = 'auth_access_token';
  static const String storageRefreshTokenKey = 'auth_refresh_token';

  // OAuth deep-link
  static const String oauthCallbackScheme = 'rbxroyale';
  static const String oauthMobileQueryParam = '?platform=mobile';
}
