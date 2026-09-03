import 'package:flutter/foundation.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

final _localizedNameField = RegExp(r'^name_[A-Za-z]{2,3}(-[A-Za-z]+)?$');
final _localizedNameToken = RegExp(r'\{(name_[A-Za-z0-9-]+)\}');

bool get _mapboxLanguageSupported =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// Streets v8 language field for [languageCode].
///
/// Kazakh is not in the tileset, so [kk] keeps the local OSM `name`
/// (usually Kazakh in KZ).
String streetsLabelNameProperty(String languageCode) {
  switch (languageCode) {
    case 'ru':
      return 'name_ru';
    case 'en':
      return 'name_en';
    default:
      return 'name';
  }
}

bool streetsLabelExpressionUsesLocalizedName(Object? value) {
  if (value is String) {
    return _localizedNameField.hasMatch(value) ||
        _localizedNameToken.hasMatch(value);
  }
  if (value is List) {
    return value.any(streetsLabelExpressionUsesLocalizedName);
  }
  if (value is Map) {
    return value.values.any(streetsLabelExpressionUsesLocalizedName);
  }
  return false;
}

/// Swaps Streets `name_en` / `name_ru` / … for [nameProperty], keeping `name`
/// and `name_script` as fallbacks.
Object? rewriteStreetsLabelExpression(Object? value, String nameProperty) {
  if (value is String) {
    if (_localizedNameField.hasMatch(value)) return nameProperty;
    return value.replaceAllMapped(_localizedNameToken, (match) {
      final field = match[1]!;
      if (field == 'name_script' || !_localizedNameField.hasMatch(field)) {
        return match[0]!;
      }
      return '{$nameProperty}';
    });
  }
  if (value is List) {
    return [
      for (final item in value)
        rewriteStreetsLabelExpression(item, nameProperty),
    ];
  }
  if (value is Map) {
    return {
      for (final entry in value.entries)
        entry.key: rewriteStreetsLabelExpression(entry.value, nameProperty),
    };
  }
  return value;
}

/// Pushes the app language into Mapbox before tiles are requested.
///
/// [MapboxMapsOptions.setLanguage] is fire-and-forget over a platform
/// channel. Awaiting [getLanguage] flushes that write so [MapWidget] is
/// not built against the device locale (often Kazakh on KZ phones).
Future<void> applyMapboxLanguagePreference(String languageCode) async {
  if (!_mapboxLanguageSupported) return;
  // ignore: experimental_member_use
  MapboxMapsOptions.setLanguage(languageCode);
  try {
    // ignore: experimental_member_use
    await MapboxMapsOptions.getLanguage();
  } catch (_) {}
}

/// Streets-v12 still uses classic symbol layers; Standard ignores this.
///
/// SDK [localizeLabels] skips layers whose `text-field` is not reported as
/// an expression, which leaves KZ streets on OSM `name` (Kazakh). Rewrite
/// `name_*` ourselves after that call.
Future<void> localizeMapboxLabels(MapboxMap map, String languageCode) async {
  try {
    await map.style.localizeLabels(languageCode, null);
  } catch (_) {}
  await _rewriteStreetsLabelLayers(map, languageCode);
}

Future<void> _rewriteStreetsLabelLayers(
  MapboxMap map,
  String languageCode,
) async {
  final nameProperty = streetsLabelNameProperty(languageCode);
  final List<StyleObjectInfo?> layers;
  try {
    layers = await map.style.getStyleLayers();
  } catch (_) {
    return;
  }

  for (final layer in layers) {
    if (layer == null || layer.type != 'symbol') continue;
    try {
      final property = await map.style.getStyleLayerProperty(
        layer.id,
        'text-field',
      );
      final value = property.value;
      if (!streetsLabelExpressionUsesLocalizedName(value)) continue;
      final rewritten = rewriteStreetsLabelExpression(value, nameProperty);
      if (rewritten == null) continue;
      await map.style.setStyleLayerProperty(layer.id, 'text-field', rewritten);
    } catch (_) {}
  }
}
