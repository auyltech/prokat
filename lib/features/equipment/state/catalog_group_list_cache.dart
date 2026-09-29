import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';

/// Sticky per–catalog-group list snapshot for browse tabs.
///
/// Lazy: no entry until first successful (or error) load for that group.
/// Sticky: switching tabs restores the last [AsyncValue] when filters match.
class CatalogGroupListCache {
  final Map<String, _Snapshot> _byGroup = {};

  static String keyFor(String? catalogGroup) =>
      (catalogGroup == null || catalogGroup.isEmpty) ? '_' : catalogGroup;

  void clear() => _byGroup.clear();

  void save({
    required String? catalogGroup,
    required String? query,
    required String? city,
    required String? categoryId,
    required List<String> spec,
    required AsyncValue<QueryState<Equipment>> value,
  }) {
    _byGroup[keyFor(catalogGroup)] = _Snapshot(
      query: query,
      city: city,
      categoryId: categoryId,
      spec: List<String>.from(spec),
      value: value,
    );
  }

  /// Returns cached value when filters match a prior load for this group.
  AsyncValue<QueryState<Equipment>>? restoreIfMatch({
    required String? catalogGroup,
    required String? query,
    required String? city,
    required String? categoryId,
    required List<String> spec,
  }) {
    final snap = _byGroup[keyFor(catalogGroup)];
    if (snap == null) return null;
    if (!_same(snap.query, query) ||
        !_same(snap.city, city) ||
        !_same(snap.categoryId, categoryId) ||
        !_sameSpec(snap.spec, spec)) {
      return null;
    }
    return snap.value;
  }

  bool has(String? catalogGroup) => _byGroup.containsKey(keyFor(catalogGroup));
}

class _Snapshot {
  final String? query;
  final String? city;
  final String? categoryId;
  final List<String> spec;
  final AsyncValue<QueryState<Equipment>> value;

  const _Snapshot({
    required this.query,
    required this.city,
    required this.categoryId,
    required this.spec,
    required this.value,
  });
}

bool _same(String? a, String? b) => a == b;

bool _sameSpec(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var i = 0; i < left.length; i++) {
    if (left[i] != right[i]) return false;
  }
  return true;
}
