import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/theme/theme_provider.dart';

void main() {
  test('theme mode round-trips through storage values', () {
    expect(themeModeToStorage(ThemeMode.light), 'light');
    expect(themeModeToStorage(ThemeMode.dark), 'dark');
    expect(themeModeToStorage(ThemeMode.system), 'system');

    expect(themeModeFromStorage('light'), ThemeMode.light);
    expect(themeModeFromStorage('dark'), ThemeMode.dark);
    expect(themeModeFromStorage('system'), ThemeMode.system);
    expect(themeModeFromStorage(null), ThemeMode.system);
    expect(themeModeFromStorage('unknown'), ThemeMode.system);
  });
}
