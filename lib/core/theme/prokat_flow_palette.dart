import 'package:flutter/material.dart';
import 'package:prokat/core/theme/app_fonts.dart';

/// Palette for the refreshed client/owner flow. Screens opt in gradually.
@immutable
class ProkatFlowPalette {
  final Color background;
  final Color surface;
  final Color primary;
  final Color primarySoft;
  final Color title;
  final Color secondary;
  final Color border;
  final Color success;

  const ProkatFlowPalette({
    required this.background,
    required this.surface,
    required this.primary,
    required this.primarySoft,
    required this.title,
    required this.secondary,
    required this.border,
    required this.success,
  });

  static ProkatFlowPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  /// Filled controls keep white content readable in both appearance modes.
  Color get filledPrimary => light.primary;

  /// Material controls and inherited text share the same opt-in presets.
  ThemeData themeFor(ThemeData base) => base.copyWith(
    scaffoldBackgroundColor: background,
    textTheme: base.textTheme.apply(
      fontFamily: AppFonts.manropeFamily,
      bodyColor: title,
      displayColor: title,
    ),
    colorScheme: base.colorScheme.copyWith(
      primary: filledPrimary,
      onPrimary: Colors.white,
      surface: surface,
      onSurface: title,
      outline: border,
    ),
  );

  static const light = ProkatFlowPalette(
    background: Color(0xFFF3F6FC),
    surface: Colors.white,
    primary: Color(0xFF3265F4),
    primarySoft: Color(0xFFEAF0FF),
    title: Color(0xFF142750),
    secondary: Color(0xFF6C7895),
    border: Color(0xFFDDE5F3),
    success: Color(0xFF11966D),
  );

  static const dark = ProkatFlowPalette(
    background: Color(0xFF12192A),
    surface: Color(0xFF202B42),
    primary: Color(0xFF79A0FF),
    primarySoft: Color(0xFF263D70),
    title: Color(0xFFF3F6FF),
    secondary: Color(0xFFADB9D2),
    border: Color(0xFF3A4968),
    success: Color(0xFF68D6AE),
  );
}
