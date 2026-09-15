import 'package:flutter/material.dart';

final class AppSelectionTheme {
  final Color fillSelected;
  final Color fillUnselected;
  final Color border;
  final Color borderError;
  final Color iconOnFill;
  final List<BoxShadow> uncheckedShadows;

  const AppSelectionTheme({
    required this.fillSelected,
    required this.fillUnselected,
    required this.border,
    required this.borderError,
    required this.iconOnFill,
    required this.uncheckedShadows,
  });
}
