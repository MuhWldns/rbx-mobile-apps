import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants.dart';

/// Secure-storage wrapper for the access + refresh JWT pair issued by the
/// backend mobile OAuth flow.
///
/// Tokens are persisted to Keychain (iOS) / EncryptedSharedPreferences
/// (Android). All methods are async and idempotent.
class AuthStorage {
  AuthStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  Future<void> save({
    required String access,
    required String refresh,
  }) async {
    await _storage.write(
      key: AppConstants.storageAccessTokenKey,
      value: access,
    );
    await _storage.write(
      key: AppConstants.storageRefreshTokenKey,
      value: refresh,
    );
  }

  Future<String?> readAccess() =>
      _storage.read(key: AppConstants.storageAccessTokenKey);

  Future<String?> readRefresh() =>
      _storage.read(key: AppConstants.storageRefreshTokenKey);

  Future<void> clear() async {
    await _storage.delete(key: AppConstants.storageAccessTokenKey);
    await _storage.delete(key: AppConstants.storageRefreshTokenKey);
  }

  Future<bool> hasAccess() async {
    final v = await readAccess();
    return v != null && v.isNotEmpty;
  }
}
