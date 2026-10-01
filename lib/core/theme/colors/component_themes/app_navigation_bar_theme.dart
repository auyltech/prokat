import 'package:flutter/material.dart';

/// Press feedback comes from [AppRippleTheme].
final class AppNavigationBarTheme {
  final Color background;
  final Color divider;
  final Color selected;
  final Color ownerSelected;
  final Color unselected;

  const AppNavigationBarTheme({
    required this.background,
    required this.divider,
    required this.selected,
    required this.ownerSelected,
    required this.unselected,
  });
}
