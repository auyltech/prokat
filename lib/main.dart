import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/app.dart';
import 'package:prokat/firebase_options.dart';

// This line handles the platform check at compile time
import 'package:prokat/map_setup_stub.dart'
    if (dart.library.io) 'package:prokat/setup_mapbox.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    setupMapbox();
  }

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      Firebase.app();
    }
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      Firebase.app();
    } else {
      rethrow;
    }
  }

  runApp(const ProviderScope(child: MyApp()));
}
