import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void setupMapbox() {
  final runtimeToken = dotenv.env['MAPBOX_TOKEN'];

  // Fallback to build-time token:
  // flutter run --dart-define=MAPBOX_TOKEN=...
  // (or --dart-define-from-file=.env)
  const buildTimeToken = String.fromEnvironment(
    'MAPBOX_TOKEN',
    defaultValue: '',
  );

  final token = (runtimeToken != null && runtimeToken.isNotEmpty)
      ? runtimeToken
      : buildTimeToken;

  if (token.isNotEmpty) {
    MapboxOptions.setAccessToken(token);
  }
}
