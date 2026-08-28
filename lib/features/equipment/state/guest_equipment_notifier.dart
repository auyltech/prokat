import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/providers/locale_provider.dart';
import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/providers/equipment_dependencies.dart';
import 'package:prokat/features/equipment/state/equipment_service.dart';

class GuestEquipmentNotifier extends AsyncNotifier<QueryState<Equipment>> {
  EquipmentService get api => ref.read(equipmentServiceProvider);

  Future<void>? _refreshing;
  int? _refreshingGeneration;
  int _requestGeneration = 0;

  String? _query;
  String? _city;
  String? _categoryId;
  List<String> _spec = const [];

  @override
  Future<QueryState<Equipment>> build() async {
    return _fetchPage(1);
  }

  Future<QueryState<Equipment>> _fetchPage(int page) async {
    final locale = ref.read(localeProvider);

    final response = await api.getGuestEquipment(
      locale: locale.languageCode.toUpperCase(),
      page: page,
      itemsPerPage: 10,
      query: _query,
      city: _city,
      categoryId: _categoryId,
      spec: _spec,
    );

    if (!response.success) {
      throw Exception(response.message);
    }

    final items = response.data ?? [];

    return QueryState(
      items: items,
      page: page,
      itemsPerPage: 10,
      count: items.length,
      lastFetchedAt: DateTime.now(),
    );
  }

  Future<void> refresh() {
    return _refreshForGeneration(_requestGeneration);
  }

  Future<void> _refreshForGeneration(int generation) {
    final active = _refreshing;
    if (active != null && _refreshingGeneration == generation) return active;

    final operation = _refresh(generation);
    _refreshing = operation;
    _refreshingGeneration = generation;
    return operation.whenComplete(() {
      if (identical(_refreshing, operation)) {
        _refreshing = null;
        _refreshingGeneration = null;
      }
    });
  }

  Future<void> _refresh(int generation) async {
    try {
      final previous = state.valueOrNull;

      if (previous == null) {
        if (state.isLoading) {
          try {
            await future;
            return;
          } catch (_) {}
        }
        if (generation != _requestGeneration) return;
        state = const AsyncLoading();
        final next = await AsyncValue.guard(() => _fetchPage(1));
        if (generation == _requestGeneration) state = next;
        return;
      }

      if (generation != _requestGeneration) return;
      state = AsyncData(previous.copyWith(isRefreshing: true));
      try {
        final next = await _fetchPage(1);
        if (generation == _requestGeneration) state = AsyncData(next);
      } catch (error) {
        if (generation == _requestGeneration) {
          state = AsyncData(previous.withRefreshError(error));
        }
      }
    } catch (_) {
      // Keep failures inside AsyncValue so unawaited UI callers cannot crash.
    }
  }

  Future<void> loadMore() async {
    // Guest catalog is a demo slice of at most 10 items; never page further.
  }

  Future<void> setFilters({
    String? query,
    String? city,
    String? categoryId,
    List<String>? spec,
  }) async {
    try {
      final nextSpec = spec ?? _spec;
      final changed =
          _query != query ||
          _city != city ||
          _categoryId != categoryId ||
          !_sameSpec(_spec, nextSpec);
      _query = query;
      _city = city;
      _categoryId = categoryId;
      _spec = List<String>.from(nextSpec);

      if (!changed) {
        await refreshIfStale();
        return;
      }
      final generation = ++_requestGeneration;
      if (state.isLoading) {
        try {
          await future;
        } catch (_) {}
      }
      await _refreshForGeneration(generation);
    } catch (_) {
      // Network errors stay in provider state for the catalog error UI.
    }
  }

  Future<void> clearFilters() async {
    try {
      final changed =
          _query != null ||
          _city != null ||
          _categoryId != null ||
          _spec.isNotEmpty;
      _query = null;
      _city = null;
      _categoryId = null;
      _spec = const [];

      if (changed) {
        final generation = ++_requestGeneration;
        await _refreshForGeneration(generation);
      } else {
        await refreshIfStale();
      }
    } catch (_) {
      // Network errors stay in provider state for the catalog error UI.
    }
  }

  Future<void> invalidate() async {
    final current = state.valueOrNull;

    if (current == null) return;

    state = AsyncData(current.copyWith(lastFetchedAt: () => null));
  }

  Future<void> refreshIfStale() async {
    try {
      if (state.isLoading) {
        try {
          await future;
        } catch (_) {}
      }
      final current = state.valueOrNull;

      if (current == null) {
        await refresh();
        return;
      }

      if (current.isStale) {
        await refresh();
      }
    } catch (_) {
      // AsyncError.value must not escape to unawaited MainScreen callers.
    }
  }

  String? get query => _query;

  String? get city => _city;

  String? get categoryId => _categoryId;
}

bool _sameSpec(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var i = 0; i < left.length; i++) {
    if (left[i] != right[i]) return false;
  }
  return true;
}
