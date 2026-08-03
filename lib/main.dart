import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/app.dart';
import 'package:prokat/firebase_options.dart';

// Handles the platform check at compile time
import 'package:prokat/map_setup_stub.dart'
    if (dart.library.io) 'package:prokat/setup_mapbox.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Perform short, non-UI background work here.
}

void main() async {
  //  Ensure binding is active before any async plugin calls
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase FIRST before setting up background messaging listeners
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      Firebase.app();
    }
  } catch (e) {
    if (!e.toString().contains('duplicate-app')) {
      rethrow;
    }
  }

  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? const AppleDebugProvider()
          : const AppleAppAttestWithDeviceCheckFallbackProvider(),
    );
  }

  //  Register background listener AFTER Firebase is initialized
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  //  Initialize platform-specific map setups
  if (!kIsWeb) {
    setupMapbox();
  }

  runApp(const ProviderScope(child: MyApp()));
}
