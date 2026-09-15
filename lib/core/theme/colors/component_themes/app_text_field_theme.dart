import 'package:flutter/material.dart';

final class AppTextFieldTheme {
  final Color background;
  final Color backgroundDisabled;
  final Color backgroundFocused;
  final Color border;
  final Color borderFocused;
  final Color borderError;
  final Color focusHalo;
  final LinearGradient focusGradient;
  final Color text;
  final Color textDisabled;
  final Color hint;
  final Color label;
  final Color caption;
  final Color cursor;

  const AppTextFieldTheme({
    required this.background,
    required this.backgroundDisabled,
    required this.backgroundFocused,
    required this.border,
    required this.borderFocused,
    required this.borderError,
    required this.focusHalo,
    required this.focusGradient,
    required this.text,
    required this.textDisabled,
    required this.hint,
    required this.label,
    required this.caption,
    required this.cursor,
  });
}
