import 'package:flutter/material.dart';

/// Single press feedback for every tappable surface (ink splash + highlight).
final class AppRippleTheme {
  final Color splash;
  final Color highlight;

  const AppRippleTheme({required this.splash, required this.highlight});

  /// For [ButtonStyle.overlayColor]: [splash] while pressed, [highlight]
  /// on hover / focus.
  WidgetStateProperty<Color?> get overlay =>
      WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) return splash;
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return highlight;
        }
        return null;
      });
}
