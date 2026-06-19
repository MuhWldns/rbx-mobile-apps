import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../models/user.dart';

class UserService {
  UserService({required this.dio});

  final Dio dio;

  /// Fetch current authenticated user. Returns null if backend says
  /// `{user: null}` or any non-200 response.
  Future<User?> fetchMe() async {
    try {
      final res = await dio.get<Map<String, dynamic>>(AppConstants.authMe);
      debugPrint('[UserService] /auth/me status=${res.statusCode} body=${res.data}');
      if (res.statusCode != 200) return null;
      final data = res.data;
      final raw = data?['user'];
      if (raw is Map<String, dynamic>) {
        return User.fromJson(raw);
      }
      debugPrint('[UserService] /auth/me returned user=$raw (not a Map)');
      return null;
    } catch (e, st) {
      debugPrint('[UserService] /auth/me threw: $e\n$st');
      return null;
    }
  }

  /// Bind a Roblox user id to the current account. Throws on non-200.
  Future<Map<String, String>> saveRobloxId(String robloxUserId) async {
    final res = await dio.put<Map<String, dynamic>>(
      AppConstants.userRobloxId,
      data: {'robloxUserId': robloxUserId},
    );
    final data = res.data ?? const <String, dynamic>{};
    if (res.statusCode != 200) {
      throw Exception(data['error'] ?? 'Failed to save Roblox ID');
    }
    return {
      'username': (data['robloxUsername'] as String?) ?? '',
      'displayName': (data['robloxDisplayName'] as String?) ?? '',
    };
  }
}
