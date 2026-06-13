class AppConstants {
  AppConstants._();

  static const String apiBaseUrl = 'https://api-rbx.muhwldns.me';
  static const String authGoogle = '$apiBaseUrl/auth/google';
  static const String authDiscord = '$apiBaseUrl/auth/discord';
  static const String authMe = '$apiBaseUrl/auth/me';
  static const String authLogout = '$apiBaseUrl/auth/logout';
  static const String userRobloxId = '$apiBaseUrl/user/roblox-id';
  static const String topupCreate = '$apiBaseUrl/topup/create';
  static String topupStatus(String reference) =>
      '$apiBaseUrl/topup/status/$reference';
  static const String licenses = '$apiBaseUrl/licenses';

  // Cookie key
  static const String sessionCookieKey = 'connect.sid';

  // Storage keys
  static const String storageCookieKey = 'session_cookie';
}
