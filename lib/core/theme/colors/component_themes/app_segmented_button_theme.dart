import 'package:flutter/material.dart';

final class AppSegmentedButtonTheme {
  final Color selectedBackground;
  final Color selectedContent;
  final Color unselectedBackground;
  final Color unselectedBorder;
  final Color unselectedContent;
  final double disabledOpacity;

  const AppSegmentedButtonTheme({
    required this.selectedBackground,
    required this.selectedContent,
    required this.unselectedBackground,
    required this.unselectedBorder,
    required this.unselectedContent,
    this.disabledOpacity = 0.45,
  });
}
