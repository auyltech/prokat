import 'package:flutter/material.dart';

class AppTheme {
  // A professional, deep and vibrant orange accent color
  static const Color accent = Color.fromARGB(255, 0, 72, 155);
  static const Color white = Color.fromARGB(255, 255, 255, 255);

  // Dark mode colors extracted from the current app
  static const Color darkBackground = Color(0xFF121417);
  static const Color darkCard = Color(0xFF1E2125);

  // Light mode subtle colors
  static const Color lightBackground = Color.fromARGB(255, 255, 255, 255);
  static const Color lightCard = Colors.white;

  // ---------- Text Colors ----------

  // Light
  static const Color lightTextPrimary = Color(0xFF1C1E21);
  static const Color lightTextSecondary = Color(0xFF5F6368);
  static const Color lightTextTertiary = Color(0xFF9AA0A6);
  static const Color lightTextDisabled = Color(0xFFB0B4B9);

  // Dark
  static const Color darkTextPrimary = Color(0xFFE3E6EB);
  static const Color darkTextSecondary = Color(0xFFB0B5BD);
  static const Color darkTextTertiary = Color(0xFF8A8F98);
  static const Color darkTextDisabled = Color(0xFF5F6368);

  /// Light Theme Configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: accent,
            primary: accent,
            brightness: Brightness.light,
            surface: lightCard,
          ).copyWith(
            surface: lightCard, // or darkCard
            onSurface: lightTextPrimary, // or darkTextPrimary
            onPrimary: white,
          ),
      scaffoldBackgroundColor: lightBackground,
      cardColor: lightCard,
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
        titleTextStyle: TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.black87),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: lightTextPrimary),
        displayMedium: TextStyle(color: lightTextPrimary),
        displaySmall: TextStyle(color: lightTextPrimary),

        headlineLarge: TextStyle(
          color: lightTextPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
        ),
        headlineMedium: TextStyle(color: lightTextPrimary),
        headlineSmall: TextStyle(color: lightTextPrimary),

        titleLarge: TextStyle(
          color: lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        titleMedium: TextStyle(
          color: lightTextSecondary,
          fontSize: 14,
          fontWeight: FontWeight.normal,
          letterSpacing: 0.5,
        ),
        titleSmall: TextStyle(color: lightTextSecondary),

        bodyLarge: TextStyle(
          color: lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: TextStyle(
          color: lightTextPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodySmall: TextStyle(color: lightTextTertiary, fontSize: 14),

        labelLarge: TextStyle(
          color: lightTextSecondary,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
        labelMedium: TextStyle(
          color: lightTextSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
        labelSmall: TextStyle(
          color: lightTextSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  /// Dark Theme Configuration
  /// Dark Theme Configuration
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: accent,
            primary: accent,
            brightness: Brightness.dark,
            surface: darkCard,
          ).copyWith(
            surface: darkCard,
            onSurface: darkTextPrimary,
            onPrimary: white,
          ),
      scaffoldBackgroundColor: darkBackground,
      cardColor: darkCard,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: darkTextPrimary),
        titleTextStyle: TextStyle(
          color: darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      iconTheme: const IconThemeData(color: darkTextSecondary),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: darkTextPrimary),
        displayMedium: TextStyle(color: darkTextPrimary),
        displaySmall: TextStyle(color: darkTextPrimary),

        headlineLarge: TextStyle(
          color: darkTextPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
        ),
        headlineMedium: TextStyle(color: darkTextPrimary),
        headlineSmall: TextStyle(color: darkTextPrimary),

        titleLarge: TextStyle(
          color: darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        titleMedium: TextStyle(
          color: darkTextSecondary,
          fontSize: 14,
          fontWeight: FontWeight.normal,
          letterSpacing: 0.5,
        ),
        titleSmall: TextStyle(color: darkTextSecondary),

        bodyLarge: TextStyle(
          color: darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: TextStyle(
          color: darkTextPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodySmall: TextStyle(color: darkTextTertiary, fontSize: 14),

        labelLarge: TextStyle(
          color: darkTextSecondary,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
        labelMedium: TextStyle(
          color: darkTextSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
        labelSmall: TextStyle(
          color: darkTextSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
