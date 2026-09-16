import 'package:flutter/material.dart';

final class AppElevatedButtonTheme {
  final Color background;
  final Color content;
  final Color contentDisabled;
  final Color destructiveBackground;
  final double disabledOpacity;

  const AppElevatedButtonTheme({
    required this.background,
    required this.content,
    required this.contentDisabled,
    required this.destructiveBackground,
    this.disabledOpacity = 0.45,
  });
}
