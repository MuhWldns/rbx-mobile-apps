import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_webview.dart';
import '../widgets/gradient_button.dart';
import '../widgets/panel_card.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: PanelCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Text(
                  'LOGIN',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
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

                // OAuth Buttons
                GradientButton(
                  text: 'Continue with Google',
                  onPressed: () => _startOAuth(context, AppConstants.authGoogle),
                ),
                const SizedBox(height: 12),
                _OutlineButton(
                  text: 'Continue with Discord',
                  onPressed: () => _startOAuth(context, AppConstants.authDiscord),
                ),
                const SizedBox(height: 32),

                // Info box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.08),
                    ),
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
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
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

  void _startOAuth(BuildContext context, String url) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AuthWebView(
          authUrl: url,
          onSessionObtained: (cookie) async {
            final authProvider =
                Provider.of<AuthProvider>(context, listen: false);
            await authProvider.onSessionObtained(cookie);
            if (context.mounted) {
              Navigator.of(context).pop(); // Close WebView
              // Router redirect will handle navigation
            }
          },
          onCancel: () {
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}

/// Outline-style button for secondary OAuth option.
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
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
