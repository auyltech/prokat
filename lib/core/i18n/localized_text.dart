import 'dart:convert';

Map<String, dynamic>? _asStringKeyedMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  if (value is String && value.trim().isNotEmpty) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
  }
  return null;
}

String? _readLocaleEntry(dynamic entry, String field) {
  if (entry is String) {
    final trimmed = entry.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  final map = _asStringKeyedMap(entry);
  if (map == null) return null;
  final value = map[field]?.toString().trim() ?? '';
  return value.isEmpty ? null : value;
}

String _pickFromMap(
  Map<String, dynamic> i18n,
  String languageCode, {
  required String field,
}) {
  final code = languageCode.toLowerCase();
  for (final locale in [code, 'ru', 'en', 'kk']) {
    final direct =
        _readLocaleEntry(i18n[locale], field) ??
        _readLocaleEntry(i18n[locale.toUpperCase()], field);
    if (direct != null) return direct;
  }
  return '';
}

/// Chat `meta.i18n` is `{ ru, kk, en }` strings.
/// Notification `data.i18n` is `{ ru: { title, body }, ... }` (object or JSON string).
String pickLocalizedText(
  dynamic i18n, {
  required String languageCode,
  String field = 'body',
  String fallback = '',
}) {
  final map = _asStringKeyedMap(i18n);
  if (map == null) return fallback;
  final picked = _pickFromMap(map, languageCode, field: field);
  return picked.isEmpty ? fallback : picked;
}
