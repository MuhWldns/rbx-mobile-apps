import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'auth/auth_service.dart';
import 'auth/dio_client.dart';
import 'providers/auth_provider.dart';
import 'services/license_service.dart';
import 'services/topup_service.dart';
import 'services/user_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final stack = buildAuthStack();
  final userService = UserService(dio: stack.dio);
  final topUpService = TopUpService(dio: stack.dio);
  final licenseService = LicenseService(dio: stack.dio);

  final authProvider = AuthProvider(
    authService: stack.auth,
    userService: userService,
  );
  await authProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        Provider<AuthService>.value(value: stack.auth),
        Provider<UserService>.value(value: userService),
        Provider<TopUpService>.value(value: topUpService),
        Provider<LicenseService>.value(value: licenseService),
      ],
      child: const App(),
    ),
  );
}
