import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/bootstrap/firebase_bootstrap.dart';
import 'package:prokat/core/config/env.dart';
import 'package:prokat/firebase_options.dart';
import 'package:prokat/setup_mapbox.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  // Perform short, non-UI background work here.
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final supportsMapbox =
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  if (supportsMapbox) {
    MapboxConfig.ensureInitialized();
  }

  final supportsBackgroundMessaging =
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  if (Env.firebaseServicesEnabled &&
      Env.pushNotificationsEnabled &&
      supportsBackgroundMessaging) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  runApp(const ProviderScope(child: FirebaseBootstrap()));
}
