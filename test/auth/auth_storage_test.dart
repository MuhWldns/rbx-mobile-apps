import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rbx_mobile_apps/auth/auth_storage.dart';
import 'package:rbx_mobile_apps/core/constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // In-memory mock for the flutter_secure_storage MethodChannel.
  late Map<String, String> backing;
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  setUp(() {
    backing = <String, String>{};
    TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      final args = (call.arguments as Map?)?.cast<String, dynamic>() ?? {};
      final key = args['key'] as String?;
      switch (call.method) {
        case 'write':
          if (key != null) backing[key] = args['value'] as String? ?? '';
          return null;
        case 'read':
          return key == null ? null : backing[key];
        case 'delete':
          if (key != null) backing.remove(key);
          return null;
        case 'readAll':
          return Map<String, String>.from(backing);
        case 'deleteAll':
          backing.clear();
          return null;
        case 'containsKey':
          return key != null && backing.containsKey(key);
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('AuthStorage', () {
    test('save persists access and refresh under correct keys', () async {
      final s = AuthStorage(storage: const FlutterSecureStorage());
      await s.save(access: 'A.JWT', refresh: 'R.OPAQUE');

      expect(backing[AppConstants.storageAccessTokenKey], 'A.JWT');
      expect(backing[AppConstants.storageRefreshTokenKey], 'R.OPAQUE');
    });

    test('readAccess and readRefresh return saved values', () async {
      final s = AuthStorage(storage: const FlutterSecureStorage());
      await s.save(access: 'A1', refresh: 'R1');

      expect(await s.readAccess(), 'A1');
      expect(await s.readRefresh(), 'R1');
    });

    test('readAccess returns null when nothing stored', () async {
      final s = AuthStorage(storage: const FlutterSecureStorage());
      expect(await s.readAccess(), isNull);
      expect(await s.readRefresh(), isNull);
    });

    test('clear deletes both tokens', () async {
      final s = AuthStorage(storage: const FlutterSecureStorage());
      await s.save(access: 'A', refresh: 'R');
      await s.clear();

      expect(await s.readAccess(), isNull);
      expect(await s.readRefresh(), isNull);
      expect(backing.containsKey(AppConstants.storageAccessTokenKey), false);
      expect(backing.containsKey(AppConstants.storageRefreshTokenKey), false);
    });

    test('hasAccess reflects presence', () async {
      final s = AuthStorage(storage: const FlutterSecureStorage());
      expect(await s.hasAccess(), false);

      await s.save(access: 'A', refresh: 'R');
      expect(await s.hasAccess(), true);

      await s.clear();
      expect(await s.hasAccess(), false);
    });
  });
}
