import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/theme/app_theme.dart';

void main() {
  test('dark theme dialog actions use onSurface', () {
    final theme = AppTheme.darkTheme;
    const enabled = <WidgetState>{};

    expect(
      theme.textButtonTheme.style?.foregroundColor?.resolve(enabled),
      theme.colorScheme.onSurface,
    );
    expect(
      theme.elevatedButtonTheme.style?.foregroundColor?.resolve(enabled),
      theme.colorScheme.onSurface,
    );
  });
}
