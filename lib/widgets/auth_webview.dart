import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../core/constants.dart';

/// WebView widget for OAuth login flow using flutter_inappwebview.
///
/// Flow:
/// 1. Open OAuth URL in InAppWebView
/// 2. User completes Google/Discord login
/// 3. Backend sets httpOnly connect.sid cookie, redirects to FRONTEND_URL?login=success
/// 4. We intercept this redirect
/// 5. Use CookieManager.getCookies() which returns httpOnly cookies on Android
/// 6. Pass cookie string back to parent
class AuthWebView extends StatefulWidget {
  final String authUrl;
  final void Function(String cookie) onSessionObtained;
  final VoidCallback onCancel;

  const AuthWebView({
    super.key,
    required this.authUrl,
    required this.onSessionObtained,
    required this.onCancel,
  });

  @override
  State<AuthWebView> createState() => _AuthWebViewState();
}

class _AuthWebViewState extends State<AuthWebView> {
  bool _isLoading = true;
  bool _loginDetected = false;
  final CookieManager _cookieManager = CookieManager.instance();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onCancel,
        ),
        title: const Text('Login'),
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.authUrl)),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              useShouldOverrideUrlLoading: true,
              thirdPartyCookiesEnabled: true,
              // Use a standard Chrome user-agent to avoid Google's
              // "disallowed_useragent" block on embedded WebViews
              userAgent:
                  'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.6422.165 Mobile Safari/537.36',
            ),
            onLoadStart: (controller, url) {
              if (mounted) setState(() => _isLoading = true);
            },
            onLoadStop: (controller, url) {
              if (mounted) setState(() => _isLoading = false);

              // Check if we landed on a page with login=success
              if (!_loginDetected &&
                  url != null &&
                  url.toString().contains('login=success')) {
                _loginDetected = true;
                _extractCookie();
              }
            },
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              final url = navigationAction.request.url?.toString() ?? '';

              // Intercept redirect to FRONTEND_URL?login=success
              if (!_loginDetected && url.contains('login=success')) {
                _loginDetected = true;
                _extractCookie();
                return NavigationActionPolicy.CANCEL;
              }

              return NavigationActionPolicy.ALLOW;
            },
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  /// Extract connect.sid cookie from the WebView's cookie jar.
  /// flutter_inappwebview's CookieManager.getCookies() returns httpOnly cookies.
  Future<void> _extractCookie() async {
    try {
      final apiUri = WebUri(AppConstants.apiBaseUrl);
      final cookies = await _cookieManager.getCookies(url: apiUri);

      for (final cookie in cookies) {
        if (cookie.name == AppConstants.sessionCookieKey) {
          final cookieString = '${cookie.name}=${cookie.value}';
          widget.onSessionObtained(cookieString);
          return;
        }
      }

      // Cookie not found on exact URL, try with broader URL on the domain
      final domainUri = WebUri('https://muhwldns.me');
      final domainCookies = await _cookieManager.getCookies(url: domainUri);

      for (final cookie in domainCookies) {
        if (cookie.name == AppConstants.sessionCookieKey) {
          final cookieString = '${cookie.name}=${cookie.value}';
          widget.onSessionObtained(cookieString);
          return;
        }
      }

      // If still not found, show error
      _showError('Sesi tidak ditemukan, coba lagi.');
    } catch (e) {
      _showError('Gagal mengambil sesi: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      setState(() => _loginDetected = false);
    }
  }
}
