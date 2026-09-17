import 'package:flutter/material.dart';

final class AppOutlinedButtonTheme {
  final Color border;
  final Color borderDestructive;
  final Color borderDisabled;
  final Color content;
  final Color contentDestructive;
  final Color contentDisabled;
  final Color background;
  final double disabledOpacity;

  const AppOutlinedButtonTheme({
    required this.border,
    required this.borderDestructive,
    required this.borderDisabled,
    required this.content,
    required this.contentDestructive,
    required this.contentDisabled,
    required this.background,
    this.disabledOpacity = 0.45,
  });
}
