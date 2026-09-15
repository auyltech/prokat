import 'package:flutter/material.dart';

/// Solid toast fills. Use [content] for text and icons on those fills.
final class AppToastTheme {
  final Color info;
  final Color success;
  final Color error;
  final Color content;

  const AppToastTheme({
    required this.info,
    required this.success,
    required this.error,
    required this.content,
  });
}
