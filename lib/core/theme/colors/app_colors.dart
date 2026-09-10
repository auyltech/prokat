import 'package:flutter/material.dart';

/// Raw Prokat light palette. Widgets must use [AppColorsTheme], not this class.
abstract final class AppColors {
  static const Color primary = Color(0xFF00489B);
  static const Color amber = Color(0xFFF4B73E);
  static const Color peach = Color(0xFFFBE7D4);

  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE0E0E1);

  static const Color textPrimary = Color(0xFF1C1E21);
  static const Color textSecondary = Color(0xFF5F6368);
  static const Color textTertiary = Color(0xFF9AA0A6);
  static const Color textDisabled = Color(0xFFB0B4B9);

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  static const Color primarySoft = Color(0xFFC0DEF6);
  static const Color bubbleHim = Color(0xFFE0E0E1);

  static const Color success = Color(0xFF1B5E20);
  static const Color successSoft = Color(0xFFF2F9F3);
  static const Color danger = Color(0xFFB71C1C);
  static const Color dangerSoft = Color(0xFFFDF4F5);
  static const Color warning = Color(0xFFBF360C);
  static const Color warningSoft = Color(0xFFFFF8F1);

  static const Color validBlockIndicator = Color(0xFF00C853);

  /// Focus halo around inputs: primary at ~18%.
  static const Color inputFocusHalo = Color(0x2E00489B);

  static const Color switchThumbShadow = Color(0x0F0F1729);
}

/// Raw Prokat dark palette. Same token names as [AppColors].
abstract final class AppColorsDark {
  static const Color primary = Color(0xFF00489B);
  static const Color primaryInteractive = Color(0xFF2B6BC7);
  static const Color amber = Color(0xFFF4B73E);
  static const Color peachSoft = Color(0xFF2A221C);
  static const Color amberSoft = Color(0xFF3A2E18);

  static const Color background = Color(0xFF121417);
  static const Color surface = Color(0xFF1E2125);
  static const Color surfaceElevated = Color(0xFF262A30);
  static const Color border = Color(0xFF2E333A);

  static const Color textPrimary = Color(0xFFE3E6EB);
  static const Color textSecondary = Color(0xFFB0B5BD);
  static const Color textTertiary = Color(0xFF8A8F98);
  static const Color textDisabled = Color(0xFF5F6368);

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  static const Color primarySoft = Color(0xFF163761);
  static const Color bubbleHim = Color(0xFF3A3D43);

  static const Color success = Color(0xFFA8D5AB);
  static const Color successSoft = Color(0xFF17231C);
  static const Color danger = Color(0xFFEF9A9A);
  static const Color dangerSoft = Color(0xFF27181A);
  static const Color warning = Color(0xFFFFCC80);
  static const Color warningSoft = Color(0xFF271C14);

  static const Color validBlockIndicator = Color(0xFF00E676);

  /// Focus halo: primaryInteractive at ~28%.
  static const Color inputFocusHalo = Color(0x472B6BC7);

  static const Color switchThumbShadow = Color(0x33000000);
}
