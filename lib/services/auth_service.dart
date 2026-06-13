import 'dart:convert';
import '../core/constants.dart';
import '../core/http_client.dart';
import '../models/user.dart';

class AuthService {
  final ApiClient _client = ApiClient();

  /// Fetch current user from /auth/me.
  /// Returns null if not authenticated.
  Future<User?> fetchMe() async {
    try {
      final response = await _client.get(AppConstants.authMe);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['user'] != null) {
          return User.fromJson(data['user']);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Logout - POST /auth/logout then clear local session.
  Future<void> logout() async {
    try {
      await _client.post(AppConstants.authLogout);
    } catch (_) {
      // Ignore network errors on logout
    }
    await _client.clearSession();
  }

  /// Save Roblox User ID - PUT /user/roblox-id.
  /// Returns map with robloxUsername and robloxDisplayName on success.
  /// Throws on error.
  Future<Map<String, String>> saveRobloxId(String robloxUserId) async {
    final response = await _client.put(
      AppConstants.userRobloxId,
      body: {'robloxUserId': robloxUserId},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['error'] ?? 'Gagal menyimpan Roblox ID');
    }

    return {
      'username': data['robloxUsername'] ?? '',
      'displayName': data['robloxDisplayName'] ?? '',
    };
  }
}
