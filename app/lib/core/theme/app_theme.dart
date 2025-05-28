import 'package:flutter/material.dart';

/// BEE App Theme based on design system specifications
/// Implements momentum state colors and Material Design 3 foundation
class AppTheme {
  // Momentum State Colors
  static const Color momentumRising = Color(0xFF4CAF50);
  static const Color momentumRisingLight = Color(0xFF81C784);
  static const Color momentumRisingDark = Color(0xFF388E3C);

  static const Color momentumSteady = Color(0xFF2196F3);
  static const Color momentumSteadyLight = Color(0xFF64B5F6);
  static const Color momentumSteadyDark = Color(0xFF1976D2);

  static const Color momentumCare = Color(0xFFFF9800);
  static const Color momentumCareLight = Color(0xFFFFB74D);
  static const Color momentumCareDark = Color(0xFFF57C00);

  // Neutral Colors
  static const Color surfacePrimary = Color(0xFFFFFFFF);
  static const Color surfaceSecondary = Color(0xFFF5F5F5);
  static const Color surfaceTertiary = Color(0xFFFAFAFA);

  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textTertiary = Color(0xFF9E9E9E);

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: momentumRising,
        brightness: Brightness.light,
        primary: momentumRising,
        secondary: momentumSteady,
        tertiary: momentumCare,
        surface: surfacePrimary,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onTertiary: Colors.white,
        onSurface: textPrimary,
      ),

      // Typography
      textTheme: _buildTextTheme(Brightness.light),

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: surfacePrimary,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),

      // Card Theme
      cardTheme: const CardThemeData(
        color: surfacePrimary,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          minimumSize: const Size(120, 44),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: momentumRising,
        foregroundColor: Colors.white,
        elevation: 3,
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: momentumRising,
        brightness: Brightness.dark,
        primary: momentumRisingLight,
        secondary: momentumSteadyLight,
        tertiary: momentumCareLight,
      ),

      // Typography
      textTheme: _buildTextTheme(Brightness.dark),

      // Card Theme
      cardTheme: const CardThemeData(
        color: surfacePrimary,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          minimumSize: const Size(120, 44),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // Typography Theme Builder
  static TextTheme _buildTextTheme(Brightness brightness) {
    final Color textColor =
        brightness == Brightness.light ? textPrimary : Colors.white;
    final Color secondaryTextColor =
        brightness == Brightness.light ? textSecondary : Colors.white70;

    return TextTheme(
      // Momentum-specific typography
      headlineLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: -0.5,
        height: 1.2,
      ),

      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: -0.2,
        height: 1.2,
      ),

      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: textColor,
        letterSpacing: -0.2,
        height: 1.4,
      ),

      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColor,
        height: 1.3,
      ),

      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textColor,
        height: 1.5,
      ),

      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: secondaryTextColor,
        height: 1.4,
      ),

      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: secondaryTextColor,
        height: 1.3,
        letterSpacing: 0.5,
      ),

      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: secondaryTextColor,
        letterSpacing: 0.5,
        height: 1.3,
      ),

      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: secondaryTextColor,
        letterSpacing: 0.5,
        height: 1.3,
      ),
    );
  }

  // Momentum State Theme Extensions
  static Color getMomentumColor(MomentumState state) {
    switch (state) {
      case MomentumState.rising:
        return momentumRising;
      case MomentumState.steady:
        return momentumSteady;
      case MomentumState.needsCare:
        return momentumCare;
    }
  }

  static String getMomentumEmoji(MomentumState state) {
    switch (state) {
      case MomentumState.rising:
        return '🚀';
      case MomentumState.steady:
        return '🙂';
      case MomentumState.needsCare:
        return '🌱';
    }
  }

  static String getMomentumMessage(MomentumState state) {
    switch (state) {
      case MomentumState.rising:
        return "You're on fire! Keep up the great momentum!";
      case MomentumState.steady:
        return "You're doing well! Stay consistent!";
      case MomentumState.needsCare:
        return "Let's grow together! Every small step counts!";
    }
  }
}

// Momentum State Enum
enum MomentumState { rising, steady, needsCare }
