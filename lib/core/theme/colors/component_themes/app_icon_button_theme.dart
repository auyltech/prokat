import 'package:flutter/material.dart';
import 'package:prokat/core/theme/colors/component_themes/app_button_tone_theme.dart';

final class AppIconButtonTheme {
  final AppButtonToneTheme neutral;
  final AppButtonToneTheme primary;
  final AppButtonToneTheme success;
  final AppButtonToneTheme warning;
  final AppButtonToneTheme destructive;
  final AppButtonToneTheme inverse;
  final Color contentDisabled;
  final Color backgroundDisabled;
  final Color borderDisabled;
  final double disabledOpacity;

  const AppIconButtonTheme({
    required this.neutral,
    required this.primary,
    required this.success,
    required this.warning,
    required this.destructive,
    required this.inverse,
    required this.contentDisabled,
    required this.backgroundDisabled,
    required this.borderDisabled,
    this.disabledOpacity = 0.45,
  });
}
