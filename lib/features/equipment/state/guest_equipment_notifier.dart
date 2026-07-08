import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/providers/guest_equipment_provider.dart';
import 'package:prokat/features/equipment/state/equipment_service.dart';

class GuestEquipmentNotifier extends AsyncNotifier<QueryState<Equipment>> {
  late final EquipmentService api;

  String? _query;
  String? _city;
  String? _categoryId;

  @override
  Future<QueryState<Equipment>> build() async {
    api = ref.read(equipmentServiceProvider);

    return _fetchPage(1);
  }

  Future<QueryState<Equipment>> _fetchPage(int page) async {
    final response = await api.getGuestEquipment(
      page: page,
      itemsPerPage: 10,
      query: _query,
      city: _city,
      categoryId: _categoryId,
    );

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

  Future<void> refresh() async {
    final previous = state.value;

    if (previous == null) {
      state = const AsyncLoading();
    } else {
      state = AsyncData(previous.copyWith(isRefreshing: true));
    }

    state = await AsyncValue.guard(() async {
      return _fetchPage(1);
    });
  }

  Future<void> loadMore() async {
    final current = state.value;

    if (current == null) return;

    if (!current.hasMore) return;

    if (current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final nextPage = current.page + 1;

      final response = await api.getGuestEquipment(
        page: nextPage,
        itemsPerPage: current.itemsPerPage,
        query: _query,
        city: _city,
        categoryId: _categoryId,
      );

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
          lastFetchedAt: DateTime.now(),
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  Future<void> setFilters({
    String? query,
    String? city,
    String? categoryId,
  }) async {
    _query = query;
    _city = city;
    _categoryId = categoryId;

    await refresh();
  }

  Future<void> clearFilters() async {
    _query = null;
    _city = null;
    _categoryId = null;

    await refresh();
  }

  Future<void> invalidate() async {
    final current = state.value;

    if (current == null) return;

    state = AsyncData(current.copyWith(lastFetchedAt: null));
  }

  Future<void> refreshIfStale() async {
    final current = state.value;

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
