import 'package:flutter/material.dart';

final class AppOutlinedButtonTheme {
  final Color border;
  final Color borderDisabled;
  final Color content;
  final Color contentDisabled;
  final Color background;
  final double disabledOpacity;

  const AppOutlinedButtonTheme({
    required this.border,
    required this.borderDisabled,
    required this.content,
    required this.contentDisabled,
    required this.background,
    this.disabledOpacity = 0.45,
  });
}
