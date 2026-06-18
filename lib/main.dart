import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:prokat/app.dart';
import 'package:prokat/firebase_options.dart';

// This line handles the platform check at compile time
import 'package:prokat/map_setup_stub.dart'
    if (dart.library.io) 'package:prokat/setup_mapbox.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // If .env isn't packaged (or missing), fall back to --dart-define tokens.
    }
  }

  // This will call the real function on Mobile and the empty stub on Web
  setupMapbox();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      Firebase.app(); // Safely re-use the natively initialized application
    }
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      Firebase.app(); // Fail silently and attach to the active instance if a race condition occurred
    } else {
      rethrow; // Pass along actual initialization failures
    }
  }

  runApp(const ProviderScope(child: MyApp()));
}
