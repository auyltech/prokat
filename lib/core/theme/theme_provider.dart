import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:prokat/core/storage/secure_storage_client.dart';

const themeModeStorageKey = 'app_theme_mode';

ThemeMode themeModeFromStorage(String? value) {
  switch (value) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    case 'system':
      return ThemeMode.system;
    default:
      return ThemeMode.system;
  }
}

String themeModeToStorage(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:
      return 'light';
    case ThemeMode.dark:
      return 'dark';
    case ThemeMode.system:
      return 'system';
  }
}

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._storage) : super(ThemeMode.system) {
    unawaited(_loadPersisted());
  }

  final FlutterSecureStorage _storage;

  Future<void> _loadPersisted() async {
    try {
      final saved = await _storage.read(key: themeModeStorageKey);
      if (saved == null || saved.isEmpty) return;
      state = themeModeFromStorage(saved);
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _storage.write(
      key: themeModeStorageKey,
      value: themeModeToStorage(mode),
    );
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  return ThemeModeNotifier(SecureStorageClient.instance);
});
