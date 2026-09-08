import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Style layer that paints building numbers on Mapbox Streets.
const housenumLabelLayerId = 'housenum-label';

/// Vector source / source-layer for Streets `housenum_label` (zoom ≥ 16).
const housenumCompositeSourceId = 'composite';
const housenumSourceLayerId = 'housenum_label';

/// Screen pad around the pin tip for [queryRenderedFeatures].
const housenumQueryPadPx = 36.0;

/// Ignore source hits farther than ~60 m from the pin (degree² approx).
const housenumMaxDistanceSq = 0.0005 * 0.0005;

const _houseNumPropertyKeys = ['house_num', 'housenum', 'addr:housenumber'];

String? houseNumberFromFeature(Map<String?, Object?> feature) {
  final properties = feature['properties'];
  if (properties is! Map) return null;

  for (final key in _houseNumPropertyKeys) {
    final value = properties[key]?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
  }
  return null;
}

Point? geometryPointFromFeature(Map<String?, Object?> feature) {
  final geometry = feature['geometry'];
  if (geometry is! Map) return null;
  final coords = geometry['coordinates'];
  if (coords is! List || coords.length < 2) return null;
  final lng = (coords[0] as num?)?.toDouble();
  final lat = (coords[1] as num?)?.toDouble();
  if (lng == null || lat == null) return null;
  return Point(coordinates: Position(lng, lat));
}

double pointDistanceSq(Point a, Point b) {
  final dx = (a.coordinates.lng - b.coordinates.lng).toDouble();
  final dy = (a.coordinates.lat - b.coordinates.lat).toDouble();
  return dx * dx + dy * dy;
}

/// Picks the house number whose geometry is closest to [origin].
///
/// Features without geometry are used only if nothing else matches.
String? pickNearestHouseNumber(
  Iterable<Map<String?, Object?>> features,
  Point origin, {
  double? maxDistanceSq,
}) {
  String? best;
  double? bestDist;
  String? fallback;

  for (final feature in features) {
    final number = houseNumberFromFeature(feature);
    if (number == null) continue;

    final geom = geometryPointFromFeature(feature);
    if (geom == null) {
      fallback ??= number;
      continue;
    }

    final dist = pointDistanceSq(origin, geom);
    if (maxDistanceSq != null && dist > maxDistanceSq) continue;
    if (bestDist == null || dist < bestDist) {
      bestDist = dist;
      best = number;
    }
  }

  return best ?? fallback;
}
