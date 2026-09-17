import 'package:flutter/material.dart';

final class AppNavigationBarTheme {
  final Color background;
  final Color divider;
  final Color selected;
  final Color ownerSelected;
  final Color unselected;
  final Color splash;
  final Color highlight;
  final Color ownerSplash;
  final Color ownerHighlight;

  const AppNavigationBarTheme({
    required this.background,
    required this.divider,
    required this.selected,
    required this.ownerSelected,
    required this.unselected,
    required this.splash,
    required this.highlight,
    required this.ownerSplash,
    required this.ownerHighlight,
  });
}
