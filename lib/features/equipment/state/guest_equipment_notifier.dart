import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/providers/locale_provider.dart';
import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/providers/guest_equipment_provider.dart';
import 'package:prokat/features/equipment/state/equipment_service.dart';

class GuestEquipmentNotifier extends AsyncNotifier<QueryState<Equipment>> {
  EquipmentService get api => ref.read(equipmentServiceProvider);

  Future<void>? _refreshing;
  int? _refreshingGeneration;
  int _requestGeneration = 0;

  String? _query;
  String? _city;
  String? _categoryId;

  @override
  Future<QueryState<Equipment>> build() async {
    return _fetchPage(1);
  }

  Future<QueryState<Equipment>> _fetchPage(int page) async {
    final locale = ref.watch(localeProvider);

    final response = await api.getGuestEquipment(
      locale: locale.languageCode.toUpperCase(),
      page: page,
      itemsPerPage: 10,
      query: _query,
      city: _city,
      categoryId: _categoryId,
    );

    if (!response.success) {
      throw Exception(response.message);
    }

    final items = response.data ?? [];

    return QueryState(
      items: items,
      page: page,
      itemsPerPage: 10,
      count: items.length < 10
          ? ((page - 1) * 10) + items.length
          : page * 10 + 1,
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
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    final generation = _requestGeneration;

    if (current == null) return;

    if (!current.hasMore) return;

    if (current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final locale = ref.watch(localeProvider);

      final nextPage = current.page + 1;

      final response = await api.getGuestEquipment(
        locale: locale.languageCode.toUpperCase(),
        page: nextPage,
        itemsPerPage: current.itemsPerPage,
        query: _query,
        city: _city,
        categoryId: _categoryId,
      );

      if (generation != _requestGeneration) return;

      if (!response.success || response.data == null) {
        state = AsyncData(current.copyWith(isLoadingMore: false));
        return;
      }

      final items = response.data!;

      state = AsyncData(
        current.copyWith(
          items: [...current.items, ...items],
          page: nextPage,
          count: items.length < current.itemsPerPage
              ? current.count + items.length
              : current.count + current.itemsPerPage,
          lastFetchedAt: DateTime.now,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      if (generation == _requestGeneration) {
        state = AsyncData(current.copyWith(isLoadingMore: false));
      }
    }
  }

  Future<void> setFilters({
    String? query,
    String? city,
    String? categoryId,
  }) async {
    final changed =
        _query != query || _city != city || _categoryId != categoryId;
    _query = query;
    _city = city;
    _categoryId = categoryId;

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
  }

  Future<void> clearFilters() async {
    final changed = _query != null || _city != null || _categoryId != null;
    _query = null;
    _city = null;
    _categoryId = null;

    if (changed) {
      final generation = ++_requestGeneration;
      await _refreshForGeneration(generation);
    } else {
      await refreshIfStale();
    }
  }

  Future<void> invalidate() async {
    final current = state.valueOrNull;

    if (current == null) return;

    state = AsyncData(current.copyWith(lastFetchedAt: () => null));
  }

  Future<void> refreshIfStale() async {
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
  }

  String? get query => _query;

  String? get city => _city;

  String? get categoryId => _categoryId;
}
