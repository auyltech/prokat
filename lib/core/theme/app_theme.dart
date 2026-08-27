import 'package:flutter/material.dart';

class AppTheme {
  // A professional, deep and vibrant orange accent color
  static const Color accent = Color(0xFF00489B);
  static const Color white = Color.fromARGB(255, 255, 255, 255);

  // Dark mode colors extracted from the current app
  static const Color darkBackground = Color(0xFF121417);
  static const Color darkCard = Color(0xFF1E2125);
  static const Color darkBubbleMe = Color(0xFF163761);
  static const Color darkBubbleHim = Color(0xFF3A3D43);

  // Light mode subtle colors
  static const Color lightBackground = white;
  static const Color lightCard = Colors.white;
  static const Color lightBubbleMe = Color(0xFFC0DEF6);
  static const Color lightBubbleHim = Color(0xFFE0E0E1);

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

  // Semantic status: pale tinted surfaces + darker content in light,
  // deep tinted surfaces (near darkCard) + lighter content in dark.
  static const Color lightSuccessBg = Color(0xFFF2F9F3);
  static const Color lightSuccessFg = Color(0xFF1B5E20);
  static const Color darkSuccessBg = Color(0xFF17231C);
  static const Color darkSuccessFg = Color(0xFFA8D5AB);

  static const Color lightDangerBg = Color(0xFFFDF4F5);
  static const Color lightDangerFg = Color(0xFFB71C1C);
  static const Color darkDangerBg = Color(0xFF27181A);
  static const Color darkDangerFg = Color(0xFFEF9A9A);

  static const Color lightWarningBg = Color(0xFFFFF8F1);
  static const Color lightWarningFg = Color(0xFFBF360C);
  static const Color darkWarningBg = Color(0xFF271C14);
  static const Color darkWarningFg = Color(0xFFFFCC80);

  static Color _tone(Brightness brightness, Color light, Color dark) =>
      brightness == Brightness.dark ? dark : light;

  static Color successBg(Brightness brightness) =>
      _tone(brightness, lightSuccessBg, darkSuccessBg);

  static Color successFg(Brightness brightness) =>
      _tone(brightness, lightSuccessFg, darkSuccessFg);

  static Color dangerBg(Brightness brightness) =>
      _tone(brightness, lightDangerBg, darkDangerBg);

  static Color dangerFg(Brightness brightness) =>
      _tone(brightness, lightDangerFg, darkDangerFg);

  static Color warningBg(Brightness brightness) =>
      _tone(brightness, lightWarningBg, darkWarningBg);

  static Color warningFg(Brightness brightness) =>
      _tone(brightness, lightWarningFg, darkWarningFg);

  /// Soft brand wash for invite-style surfaces (chat-bubble tokens).
  static Color brandTintBg(Brightness brightness) =>
      _tone(brightness, lightBubbleMe, darkBubbleMe);

  static Color brandTintFg(Brightness brightness) =>
      _tone(brightness, accent, lightBubbleMe);

  /// Light Theme Configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        primary: accent,
        brightness: Brightness.light,
        surface: lightCard,
        surfaceContainerHigh: lightBubbleMe,
        surfaceContainerLow: lightBubbleHim,
        onSurface: lightTextPrimary, // or darkTextPrimary
        onPrimary: accent,
      ),
      scaffoldBackgroundColor: lightBackground,
      cardColor: lightCard,
      appBarTheme: const AppBarTheme(
        backgroundColor: lightCard,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
        titleTextStyle: TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.w500,
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
          fontWeight: FontWeight.w500,
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
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        primary: accent,
        brightness: Brightness.dark,
        surface: darkCard,
        surfaceContainerHigh: darkBubbleMe,
        surfaceContainerLow: darkBubbleHim,
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
