import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Reusable panel card matching the web's glassmorphism style.
class PanelCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const PanelCard({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.panelBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.panelBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}
