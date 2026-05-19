import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

void setupMapbox() {
  // Reads MAPBOX_ACCESS_TOKEN from the build configuration
  const String mapboxToken = String.fromEnvironment(
    'MAPBOX_TOKEN',
    defaultValue: '',
  );

  if (mapboxToken.isNotEmpty) {
    MapboxOptions.setAccessToken(mapboxToken);
  } else {
    // Handle the missing token case appropriately for your app
    print("Warning: Mapbox Access Token is missing.");
  }
}
