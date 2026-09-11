import 'package:flutter/material.dart';
import 'package:prokat/core/theme/colors/app_colors_theme.dart';
import 'package:prokat/core/theme/extensions/app_theme_getter.dart';

/// Prokat typography. Public styles include theme-aware default colors.
///
/// Brandbook: Sora (display), Manrope (UI), Space Mono (price/tech).
/// Interim: all roles use Manrope until Sora/Space Mono files are added.
abstract final class AppFonts {
  static const String manropeFamily = 'Manrope';
  // TODO(Brand): switch display to Sora when font files are bundled.
  static const String displayFamily = manropeFamily;
  // TODO(Brand): switch price/technical to Space Mono when font files are bundled.
  static const String monoFamily = manropeFamily;

  static TextStyle _base({
    required double fontSize,
    required FontWeight fontWeight,
    String fontFamily = manropeFamily,
    double height = 1.2,
    double letterSpacing = 0,
  }) => TextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight,
    fontFamily: fontFamily,
    height: height,
    letterSpacing: letterSpacing,
  );

  static AppColorsTheme _colors(BuildContext context) => context.colors;

  static TextStyle display(BuildContext context) => _base(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    fontFamily: displayFamily,
  ).copyWith(color: _colors(context).text.main);

  static TextStyle headingL(BuildContext context) => _base(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    fontFamily: displayFamily,
  ).copyWith(color: _colors(context).text.main);

  static TextStyle headingM(BuildContext context) => _base(
    fontSize: 22,
    fontWeight: FontWeight.w500,
    fontFamily: displayFamily,
  ).copyWith(color: _colors(context).text.main);

  static TextStyle headingS(BuildContext context) => _base(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  ).copyWith(color: _colors(context).text.main);

  static TextStyle body16(BuildContext context) => _base(
    fontSize: 16,
    fontWeight: FontWeight.w400,
  ).copyWith(color: _colors(context).text.main);

  static TextStyle body16SemiBold(BuildContext context) => _base(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  ).copyWith(color: _colors(context).text.main);

  static TextStyle body14(BuildContext context) => _base(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  ).copyWith(color: _colors(context).text.main);

  static TextStyle body14Bold(BuildContext context) => _base(
    fontSize: 14,
    fontWeight: FontWeight.w700,
  ).copyWith(color: _colors(context).text.main);

  static TextStyle label(BuildContext context) => _base(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  ).copyWith(color: _colors(context).text.secondary);

  static TextStyle caption(BuildContext context) => _base(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  ).copyWith(color: _colors(context).text.secondary);

  static TextStyle captionMedium(BuildContext context) => _base(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  ).copyWith(color: _colors(context).text.secondary);

  static TextStyle button(BuildContext context) => _base(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  ).copyWith(color: _colors(context).text.main);

  static TextStyle price(BuildContext context) => _base(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    fontFamily: monoFamily,
  ).copyWith(color: _colors(context).text.main);

  static TextStyle technical(BuildContext context) => _base(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    fontFamily: monoFamily,
  ).copyWith(color: _colors(context).text.secondary);

  /// Hides Material error text slot without a zero-size layout jump.
  static const TextStyle collapsed = TextStyle(
    fontSize: 0,
    height: 0,
    fontFamily: manropeFamily,
  );
}
