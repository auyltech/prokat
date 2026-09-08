import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:prokat/core/utils/logger.dart';

class CrashReportingService {
  CrashReportingService._();

  static bool _initialized = false;
  static bool _collectionEnabled = false;

  static bool get _isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  static Future<void> initialize() async {
    if (_initialized || !_isSupportedPlatform) {
      return;
    }

    final crashlytics = FirebaseCrashlytics.instance;
    const collectionEnabled = !kDebugMode;
    _collectionEnabled = collectionEnabled;

    await crashlytics.setCrashlyticsCollectionEnabled(collectionEnabled);

    if (collectionEnabled) {
      FlutterError.onError = crashlytics.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stackTrace) {
        unawaited(crashlytics.recordError(error, stackTrace, fatal: true));
        return true;
      };
    }

    _initialized = true;
  }

  /// Records [error] in Crashlytics. Use [fatal] for handshake failures that
  /// previously showed up only as a misleading `AsyncError.value` crash.
  static Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
    Map<String, String>? keys,
    String? userId,
    bool fatal = false,
  }) async {
    Logger.log(
      'CrashReportingService.recordError'
      '${reason == null ? '' : ' ($reason)'}: $error\n$stackTrace',
    );

    if (!_initialized || !_isSupportedPlatform || !_collectionEnabled) {
      return;
    }

    try {
      final crashlytics = FirebaseCrashlytics.instance;
      final trimmedUserId = userId?.trim();
      if (trimmedUserId != null && trimmedUserId.isNotEmpty) {
        await crashlytics.setUserIdentifier(trimmedUserId);
      }

      final entries = keys?.entries ?? const <MapEntry<String, String>>[];
      for (final entry in entries) {
        await crashlytics.setCustomKey(entry.key, entry.value);
      }

      if (reason != null && reason.trim().isNotEmpty) {
        await crashlytics.log(reason.trim());
      }

      await crashlytics.recordError(
        error,
        stackTrace,
        reason: reason,
        fatal: fatal,
      );
    } catch (loggingError, loggingStack) {
      Logger.log(
        'CrashReportingService.recordError failed: '
        '$loggingError\n$loggingStack',
      );
    }
  }
}
