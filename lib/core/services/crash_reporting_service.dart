import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class CrashReportingService {
  CrashReportingService._();

  static const bool _enableInDebug = bool.fromEnvironment('ENABLE_CRASHLYTICS');
  static const bool _triggerTestCrash = bool.fromEnvironment(
    'CRASHLYTICS_TEST_CRASH',
  );

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
    final collectionEnabled = !kDebugMode || _enableInDebug;

    await crashlytics.setCrashlyticsCollectionEnabled(collectionEnabled);

    if (collectionEnabled) {
      FlutterError.onError = crashlytics.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stackTrace) {
        unawaited(crashlytics.recordError(error, stackTrace, fatal: true));
        return true;
      };

      assert(() {
        if (_triggerTestCrash) {
          unawaited(
            Future<void>.microtask(
              () => throw StateError('Crashlytics test crash'),
            ),
          );
        }
        return true;
      }());
    }

    _initialized = true;
  }
}
