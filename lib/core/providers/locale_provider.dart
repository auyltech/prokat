import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:prokat/core/storage/secure_storage_client.dart';
import 'package:prokat/l10n/app_localizations.dart';

const _localeStorageKey = 'app_locale';
final _supportedCodes = AppLocalizations.supportedLocales
    .map((locale) => locale.languageCode)
    .toSet();

Locale _resolveLocale(String languageCode) {
  if (_supportedCodes.contains(languageCode)) return Locale(languageCode);
  return const Locale('en');
}

Locale _systemLocale() {
  final lang = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
  return _resolveLocale(lang);
}

class LocaleNotifier extends StateNotifier<Locale> {
  final FlutterSecureStorage _storage;
  final Completer<void> _hydrated = Completer<void>();

  LocaleNotifier(this._storage) : super(_systemLocale()) {
    unawaited(_loadPersisted());
  }

  /// Completes after the saved app language is applied (or confirmed missing).
  ///
  /// Until then [state] is the phone language, which is often `kk` in KZ.
  Future<void> get hydrated => _hydrated.future;

  Future<void> _loadPersisted() async {
    try {
      final saved = await _storage.read(key: _localeStorageKey);
      if (saved != null && _supportedCodes.contains(saved)) {
        state = Locale(saved);
      }
    } finally {
      if (!_hydrated.isCompleted) _hydrated.complete();
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await _storage.write(key: _localeStorageKey, value: locale.languageCode);
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
  return LocaleNotifier(SecureStorageClient.instance);
});
