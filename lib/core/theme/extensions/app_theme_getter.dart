import 'package:flutter/material.dart';
import 'package:prokat/core/theme/colors/app_colors_theme.dart';

extension AppThemeGetter on BuildContext {
  AppColorsTheme get colors {
    final extension = Theme.of(this).extension<AppColorsTheme>();
    assert(
      extension != null,
      'AppColorsTheme missing from ThemeData.extensions. '
      'Register LightColorTheme / DarkColorTheme on MaterialApp themes.',
    );
    return extension!;
  }
}
