import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _localeStorageKey = 'app_locale';
const _supportedCodes = {'en', 'ru', 'kk'};

Locale _resolveLocale(String languageCode) {
  if (_supportedCodes.contains(languageCode)) return Locale(languageCode);
  return const Locale('en');
}

Locale _systemLocale() {
  final lang =
      WidgetsBinding.instance.platformDispatcher.locale.languageCode;
  return _resolveLocale(lang);
}

class LocaleNotifier extends StateNotifier<Locale> {
  final FlutterSecureStorage _storage;

  LocaleNotifier(this._storage) : super(_systemLocale()) {
    _loadPersisted();
  }

  Future<void> _loadPersisted() async {
    final saved = await _storage.read(key: _localeStorageKey);
    if (saved != null && _supportedCodes.contains(saved)) {
      state = Locale(saved);
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await _storage.write(
      key: _localeStorageKey,
      value: locale.languageCode,
    );
  }

  /// Maps language code to the short display label shown in the UI badge.
  static String displayCode(Locale locale) {
    switch (locale.languageCode) {
      case 'kk':
        return 'KZ';
      case 'ru':
        return 'RU';
      default:
        return 'EN';
    }
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier(const FlutterSecureStorage());
});
