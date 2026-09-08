import 'dart:math' as math;

import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:prokat/features/catalog/models/localized_names.dart';
import 'package:prokat/features/map/services/map_pin_housenum.dart';

/// Composite source-layer for Streets `road` (named streets).
const roadCompositeSourceId = housenumCompositeSourceId;
const roadSourceLayerId = 'road';
const roadLabelLayerId = 'road-label';

/// Keep streets whose geometry comes within this distance of the pin.
const roadQueryRadiusMeters = 80.0;

const _ignoredRoadClasses = {
  'ferry',
  'aerialway',
  'golf',
  'racetrack',
  'major_rail',
  'minor_rail',
  'service_rail',
};

const _maxStreetOptions = 8;

String _norm(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

String? _trimProp(Map properties, String key) {
  final value = properties[key]?.toString().trim();
  if (value == null || value.isEmpty) return null;
  return value;
}

/// Local OSM `name` is kk only when it differs from ru/en.
/// A lone `name` (typical of queried labels) is ru, not copied into en/kk.
LocalizedNames? streetNamesFromFeature(Map<String?, Object?> feature) {
  final properties = feature['properties'];
  if (properties is! Map) return null;

  final className = properties['class']?.toString();
  if (className != null && _ignoredRoadClasses.contains(className)) {
    return null;
  }

  final ru = _trimProp(properties, 'name_ru');
  final en = _trimProp(properties, 'name_en');
  final kkProp = _trimProp(properties, 'name_kk');
  final local = _trimProp(properties, 'name');
  if (ru == null && en == null && kkProp == null && local == null) return null;

  final kk =
      kkProp ??
      ((local != null && ru != null && local != ru && local != en)
          ? local
          : null);

  return LocalizedNames(
    ru: ru ?? ((en == null && kk == null) ? (local ?? '') : ''),
    en: en ?? '',
    kk: kk ?? '',
  );
}

String _firstNonEmpty(String a, String b) {
  final left = a.trim();
  if (left.isNotEmpty) return left;
  return b.trim();
}

/// Prefer a translation that is not a copy of the Russian name.
String _mergeTranslation(String a, String b, String ruA, String ruB) {
  final left = a.trim();
  final right = b.trim();
  bool distinct(String value, String ru) =>
      value.isNotEmpty && (ru.isEmpty || value != ru);
  if (distinct(left, ruA.trim())) return left;
  if (distinct(right, ruB.trim())) return right;
  return _firstNonEmpty(left, right);
}

bool _sameName(String a, String b) {
  final left = a.trim();
  final right = b.trim();
  return left.isNotEmpty && _norm(left) == _norm(right);
}

/// True when [value] is already this object's English or Kazakh name.
bool _isTranslationOf(LocalizedNames names, String value) {
  return _sameName(value, names.en) || _sameName(value, names.kk);
}

String _mergeCanonicalRu(LocalizedNames a, LocalizedNames b) {
  final left = a.ru.trim();
  final right = b.ru.trim();
  if (left.isNotEmpty && !_isTranslationOf(b, left)) return left;
  if (right.isNotEmpty && !_isTranslationOf(a, right)) return right;
  return _firstNonEmpty(left, right);
}

LocalizedNames mergeStreetNames(LocalizedNames a, LocalizedNames b) {
  return LocalizedNames(
    en: _mergeTranslation(a.en, b.en, a.ru, b.ru),
    ru: _mergeCanonicalRu(a, b),
    kk: _mergeTranslation(a.kk, b.kk, a.ru, b.ru),
  );
}

Set<String> streetMatchTokens(LocalizedNames names, {String fallback = ''}) {
  return {
    if (names.ru.trim().isNotEmpty) _norm(names.ru),
    if (names.en.trim().isNotEmpty) _norm(names.en),
    if (names.kk.trim().isNotEmpty) _norm(names.kk),
    if (fallback.trim().isNotEmpty) _norm(fallback),
  };
}

bool streetsMatch(
  LocalizedNames a,
  LocalizedNames b, {
  String aFallback = '',
  String bFallback = '',
}) {
  final left = streetMatchTokens(a, fallback: aFallback);
  final right = streetMatchTokens(b, fallback: bFallback);
  return left.isNotEmpty && left.intersection(right).isNotEmpty;
}

double distanceMeters(Point a, Point b) {
  final dLat =
      (a.coordinates.lat.toDouble() - b.coordinates.lat.toDouble()) * 111320;
  final cosLat = math.cos(a.coordinates.lat.toDouble() * math.pi / 180);
  final dLng =
      (a.coordinates.lng.toDouble() - b.coordinates.lng.toDouble()) *
      111320 *
      cosLat;
  return math.sqrt(dLat * dLat + dLng * dLng);
}

Iterable<Point> pointsFromGeometry(Map geometry) sync* {
  final type = geometry['type']?.toString();
  final coords = geometry['coordinates'];
  if (coords is! List) return;

  Iterable<Point> fromPair(Object? pair) sync* {
    if (pair is! List || pair.length < 2) return;
    final lng = (pair[0] as num?)?.toDouble();
    final lat = (pair[1] as num?)?.toDouble();
    if (lng == null || lat == null) return;
    yield Point(coordinates: Position(lng, lat));
  }

  if (type == 'Point') {
    yield* fromPair(coords);
    return;
  }
  if (type == 'LineString') {
    for (final pair in coords) {
      yield* fromPair(pair);
    }
    return;
  }
  if (type == 'MultiLineString' || type == 'Polygon') {
    for (final line in coords) {
      if (line is! List) continue;
      for (final pair in line) {
        yield* fromPair(pair);
      }
    }
  }
}

double? minDistanceMeters(Map<String?, Object?> feature, Point origin) {
  final geometry = feature['geometry'];
  if (geometry is! Map) return null;
  var best = double.infinity;
  for (final point in pointsFromGeometry(geometry)) {
    final meters = distanceMeters(origin, point);
    if (meters < best) best = meters;
  }
  return best.isFinite ? best : null;
}

class PinStreetChoice {
  const PinStreetChoice({required this.options, required this.selected});

  final List<LocalizedNames> options;
  final LocalizedNames selected;
}

/// Tile streets as dropdown options; reverse street is selected when it matches.
PinStreetChoice choosePinStreets({
  required LocalizedNames reverseStreet,
  required List<LocalizedNames> tileStreets,
  String reverseFallback = '',
}) {
  final reverseNames =
      reverseStreet.isEmpty && reverseFallback.trim().isNotEmpty
      ? LocalizedNames(ru: reverseFallback.trim())
      : reverseStreet;

  final options = <LocalizedNames>[];
  void add(LocalizedNames names) {
    if (names.isEmpty) return;
    final index = options.indexWhere((option) => streetsMatch(option, names));
    if (index >= 0) {
      options[index] = mergeStreetNames(options[index], names);
      return;
    }
    options.add(names);
  }

  for (final tile in tileStreets) {
    add(tile);
  }

  LocalizedNames? match;
  for (final option in options) {
    if (streetsMatch(option, reverseNames, bFallback: reverseFallback)) {
      match = option;
      break;
    }
  }

  if (match != null) {
    final merged = mergeStreetNames(match, reverseNames);
    final index = options.indexWhere((option) => streetsMatch(option, match!));
    if (index >= 0) options[index] = merged;
    return PinStreetChoice(options: options, selected: merged);
  }

  if (!reverseNames.isEmpty) {
    options.insert(0, reverseNames);
    return PinStreetChoice(options: options, selected: reverseNames);
  }

  final first = options.isEmpty ? reverseNames : options.first;
  return PinStreetChoice(options: options, selected: first);
}

/// Named roads within [maxDistanceMeters], nearest first.
/// Duplicate geometries are merged so label hits do not wipe `name_en` / kk.
List<LocalizedNames> pickNearbyStreets(
  Iterable<Map<String?, Object?>> features,
  Point origin, {
  double maxDistanceMeters = roadQueryRadiusMeters,
}) {
  final ranked = <({LocalizedNames names, double dist})>[];

  for (final feature in features) {
    final names = streetNamesFromFeature(feature);
    if (names == null) continue;
    final dist = minDistanceMeters(feature, origin);
    if (dist == null || dist > maxDistanceMeters) continue;
    ranked.add((names: names, dist: dist));
  }

  ranked.sort((a, b) => a.dist.compareTo(b.dist));

  final unique = <LocalizedNames>[];
  for (final item in ranked) {
    final index = unique.indexWhere(
      (option) => streetsMatch(option, item.names),
    );
    if (index >= 0) {
      unique[index] = mergeStreetNames(unique[index], item.names);
      continue;
    }
    if (unique.length >= _maxStreetOptions) continue;
    unique.add(item.names);
  }
  return unique;
}
