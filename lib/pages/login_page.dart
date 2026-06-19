import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/gradient_button.dart';
import '../widgets/panel_card.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _busyGoogle = false;
  bool _busyDiscord = false;

  Future<void> _login(Future<bool> Function() fn, {required bool google}) async {
    setState(() {
      if (google) {
        _busyGoogle = true;
      } else {
        _busyDiscord = true;
      }
    });
    final ok = await fn();
    if (!mounted) return;
    setState(() {
      _busyGoogle = false;
      _busyDiscord = false;
    });
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login failed, please try again.')),
      );
    }
    // On success the router redirect picks it up and navigates to /dashboard.
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: PanelCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('LOGIN', style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 16),
                Text(
                  'Sign in to continue',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Use Google or Discord to access your dashboard, wallet, and licenses.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                GradientButton(
                  text: 'Continue with Google',
                  isLoading: _busyGoogle,
                  onPressed: _busyGoogle || _busyDiscord
                      ? null
                      : () => _login(authProvider.loginWithGoogle, google: true),
                ),
                const SizedBox(height: 12),
                _OutlineButton(
                  text: _busyDiscord ? '...' : 'Continue with Discord',
                  onPressed: _busyGoogle || _busyDiscord
                      ? null
                      : () => _login(authProvider.loginWithDiscord, google: false),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'What happens after login',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'You will be redirected to your dashboard, and your session will stay active until you log out.',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  const _OutlineButton({required this.text, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
          backgroundColor: Colors.white.withOpacity(0.05),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
