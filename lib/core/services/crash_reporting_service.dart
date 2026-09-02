import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class CrashReportingService {
  CrashReportingService._();

  static bool _initialized = false;

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
}
