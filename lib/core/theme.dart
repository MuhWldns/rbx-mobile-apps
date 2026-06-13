import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Colors
  static const Color background = Color(0xFF0A0814);
  static const Color panelBg = Color(0xFF140D2B);
  static const Color panelBorder = Color(0x38C179FF);
  static const Color violet = Color(0xFF8B5CF6);
  static const Color fuchsia = Color(0xFFD946EF);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFCBD5E1); // slate-300
  static const Color textTertiary = Color(0xFF94A3B8); // slate-400
  static const Color textMuted = Color(0xFF64748B); // slate-500
  static const Color emerald = Color(0xFF34D399);
  static const Color rose = Color(0xFFFB7185);
  static const Color amber = Color(0xFFFBBF24);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [violet, fuchsia],
  );

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          surface: panelBg,
          primary: violet,
          secondary: fuchsia,
          onPrimary: Colors.white,
          onSurface: textPrimary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: background,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: panelBg,
          selectedItemColor: violet,
          unselectedItemColor: textTertiary,
          type: BottomNavigationBarType.fixed,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: violet.withOpacity(0.5)),
          ),
          labelStyle: const TextStyle(color: textTertiary),
          hintStyle: const TextStyle(color: textMuted),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
          headlineMedium: TextStyle(
            color: textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
          titleLarge: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(color: textSecondary, fontSize: 16),
          bodyMedium: TextStyle(color: textSecondary, fontSize: 14),
          bodySmall: TextStyle(color: textTertiary, fontSize: 12),
          labelSmall: TextStyle(
            color: violet,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.4,
          ),
        ),
      );
}
