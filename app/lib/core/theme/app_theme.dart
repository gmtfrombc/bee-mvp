import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  // Neutral Colors - Light Theme
  static const Color surfacePrimary = Color(0xFFFFFFFF);
  static const Color surfaceSecondary = Color(0xFFF5F5F5);
  static const Color surfaceTertiary = Color(0xFFFAFAFA);

  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textTertiary = Color(0xFF9E9E9E);

  // Dark Theme Colors
  static const Color darkSurfacePrimary = Color(0xFF121212);
  static const Color darkSurfaceSecondary = Color(0xFF1E1E1E);
  static const Color darkSurfaceTertiary = Color(0xFF2A2A2A);

  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB3B3B3);
  static const Color darkTextTertiary = Color(0xFF666666);

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
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
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

      // Scaffold Background
      scaffoldBackgroundColor: surfaceSecondary,
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
        surface: darkSurfacePrimary,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onTertiary: Colors.black,
        onSurface: darkTextPrimary,
      ),

      // Typography
      textTheme: _buildTextTheme(Brightness.dark),

      // App Bar Theme for Dark Mode
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurfacePrimary,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
      ),

      // Card Theme for Dark Mode
      cardTheme: CardThemeData(
        color: darkSurfaceSecondary,
        elevation: 3,
        shadowColor: Colors.black54,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          side: BorderSide(
            color: darkTextTertiary.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
      ),

      // Elevated Button Theme for Dark Mode
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          minimumSize: const Size(120, 44),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          backgroundColor: momentumRisingLight,
          foregroundColor: Colors.black,
        ),
      ),

      // Floating Action Button Theme for Dark Mode
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: momentumRisingLight,
        foregroundColor: Colors.black,
        elevation: 3,
      ),

      // Scaffold Background for Dark Mode
      scaffoldBackgroundColor: darkSurfaceSecondary,
    );
  }

  // Typography Theme Builder
  static TextTheme _buildTextTheme(Brightness brightness) {
    final Color textColor =
        brightness == Brightness.light ? textPrimary : darkTextPrimary;
    final Color secondaryTextColor =
        brightness == Brightness.light ? textSecondary : darkTextSecondary;

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

  /// Get the appropriate text color for current theme
  static Color getTextPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextPrimary
        : textPrimary;
  }

  /// Get the appropriate secondary text color for current theme
  static Color getTextSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextSecondary
        : textSecondary;
  }

  /// Get the appropriate tertiary text color for current theme
  static Color getTextTertiary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextTertiary
        : textTertiary;
  }

  /// Get the appropriate surface color for current theme
  static Color getSurfacePrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSurfacePrimary
        : surfacePrimary;
  }

  /// Get the appropriate secondary surface color for current theme
  static Color getSurfaceSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSurfaceSecondary
        : surfaceSecondary;
  }

  /// Get the appropriate tertiary surface color for current theme
  static Color getSurfaceTertiary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSurfaceTertiary
        : surfaceTertiary;
  }

  /// Get the appropriate background color for momentum gauge
  static Color getMomentumBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF3A3A3A) // Subtle gray for dark mode
        : const Color(0xFFE0E0E0); // Light gray for light mode
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
