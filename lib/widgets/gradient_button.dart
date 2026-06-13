import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Gradient button matching the web's violet→fuchsia style.
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: onPressed != null && !isLoading
              ? AppTheme.primaryGradient
              : LinearGradient(
                  colors: [
                    AppTheme.violet.withOpacity(0.5),
                    AppTheme.fuchsia.withOpacity(0.5),
                  ],
                ),
          borderRadius: BorderRadius.circular(50),
          boxShadow: onPressed != null && !isLoading
              ? [
                  BoxShadow(
                    color: AppTheme.violet.withOpacity(0.35),
                    blurRadius: 40,
                    offset: const Offset(0, 18),
                  ),
                ]
              : null,
        ),
        child: MaterialButton(
          onPressed: isLoading ? null : onPressed,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
