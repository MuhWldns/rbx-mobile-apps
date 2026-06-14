import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:rbx_mobile_apps/auth/auth_service.dart';
import 'package:rbx_mobile_apps/auth/auth_storage.dart';
import 'package:rbx_mobile_apps/providers/auth_provider.dart';
import 'package:rbx_mobile_apps/services/user_service.dart';

class _StubWebAuth implements FlutterWebAuth2Authenticator {
  @override
  Future<String> authenticate({
    required String url,
    required String callbackUrlScheme,
  }) async =>
      '';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
        case 'deleteAll':
          backing.clear();
          return null;
        case 'readAll':
          return Map<String, String>.from(backing);
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

  AuthProvider buildProvider() {
    final storage = AuthStorage(storage: const FlutterSecureStorage());
    final dio = Dio();
    final auth = AuthService(
      storage: storage,
      dio: dio,
      webAuthenticator: _StubWebAuth(),
    );
    final user = UserService(dio: dio);
    return AuthProvider(authService: auth, userService: user);
  }

  group('AuthProvider', () {
    test('initial state is loading with no user', () {
      final provider = buildProvider();
      expect(provider.isLoading, true);
      expect(provider.user, isNull);
      expect(provider.isAuthenticated, false);
    });

    test('logout notifies listeners', () async {
      final provider = buildProvider();
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.logout();

      expect(notifyCount, greaterThan(0));
      expect(provider.user, isNull);
    });
  });
}
