import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/bookings/providers/booking_mutation_provider.dart';
import 'package:prokat/features/bookings/state/booking_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OwnerActiveBookingsNotifier
    extends AsyncNotifier<QueryState<BookingModel>> {
  BookingService get api => ref.read(bookingServiceProvider);
  Future<void>? _refreshing;

  @override
  Future<QueryState<BookingModel>> build() async {
    return _fetchPage(1);
  }

  Future<QueryState<BookingModel>> _fetchPage(int page) async {
    final response = await api.getOwnerBookings(
      page: page,
      itemsPerPage: 10,
      status: "ACTIVE",
    );

    final result = response.data;
    if (!response.success || result == null) {
      throw Exception(response.message);
    }

    return QueryState(
      items: result.items,
      page: result.page,
      itemsPerPage: result.itemsPerPage,
      count: result.count,
      lastFetchedAt: DateTime.now(),
    );
  }

  Future<void> refresh() {
    final active = _refreshing;
    if (active != null) return active;
    final operation = _refresh();
    _refreshing = operation;
    return operation.whenComplete(() => _refreshing = null);
  }

  Future<void> _refresh() async {
    final previous = state.value;

    if (previous == null) {
      if (state.isLoading) {
        try {
          await future;
          return;
        } catch (_) {}
      }
      state = const AsyncLoading();
      state = await AsyncValue.guard(() => _fetchPage(1));
      return;
    }

    state = AsyncData(previous.copyWith(isRefreshing: true));
    try {
      state = AsyncData(await _fetchPage(1));
    } catch (error) {
      state = AsyncData(previous.withRefreshError(error));
    }
  }

  Future<void> loadMore() async {
    final current = state.value;

    if (current == null) return;

    if (!current.hasMore) return;

    if (current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final nextPage = current.page + 1;

      final response = await api.getOwnerBookings(
        page: nextPage,
        itemsPerPage: current.itemsPerPage,
        status: "ACTIVE",
      );

      if (!response.success || response.data == null) {
        state = AsyncData(current.copyWith(isLoadingMore: false));

        return;
      }

      final result = response.data!;

      state = AsyncData(
        current.copyWith(
          items: [...current.items, ...result.items],
          page: result.page,
          itemsPerPage: result.itemsPerPage,
          count: result.count,
          lastFetchedAt: DateTime.now,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  Future<void> invalidate() async {
    final current = state.value;

    if (current == null) return;

    state = AsyncData(current.copyWith(lastFetchedAt: () => null));
  }

  Future<void> refreshIfStale() async {
    if (state.isLoading) {
      try {
        await future;
      } catch (_) {}
    }
    final current = state.value;

    if (current == null) {
      await refresh();
      return;
    }

    if (current.isStale) {
      await refresh();
    }
  }
}
