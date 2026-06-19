import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'package:flutter/foundation.dart';
// If your Mapbox SDK requires specific package imports, leave them here

class MapboxConfig {
  /// Extracts the compile-time token and triggers an explicit runtime crash if missing.
  static String get publicToken {
    const token = String.fromEnvironment('MAPBOX_TOKEN');

    if (token.isEmpty) {
      throw StateError(
        'CRITICAL: Missing "MAPBOX_TOKEN" in your environment parameters.',
      );
    }

    return token;
  }
}

/// Native mobile initialization routine for Mapbox maps.
void setupMapbox() {
  try {
    final token = MapboxConfig.publicToken;

    // Pass the securely extracted token string directly into your Mapbox library initialization sequence
    MapboxOptions.setAccessToken(token);

    debugPrint('Mapbox initialization completed successfully.');
  } catch (e) {
    debugPrint('Mapbox Setup Failed: $e');
    rethrow; // Pass along initialization crashes so bad production distributions fail explicitly
  }
}
