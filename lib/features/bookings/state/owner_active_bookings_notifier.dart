import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/bookings/providers/booking_mutation_provider.dart';
import 'package:prokat/features/bookings/state/booking_service.dart';
import 'package:riverpod/riverpod.dart';

class OwnerActiveBookingsNotifier
    extends AsyncNotifier<QueryState<BookingModel>> {
  late final BookingService api;

  @override
  Future<QueryState<BookingModel>> build() async {
    api = ref.read(bookingApiProvider);

    return _fetchPage(1);
  }

  Future<QueryState<BookingModel>> _fetchPage(int page) async {
    final response = await api.getClientBookings(
      page: page,
      itemsPerPage: 10,
      status: "ACTIVE",
    );

    final result = response.data;

    return QueryState(
      items: result?.items ?? [],
      page: result?.page ?? 1,
      itemsPerPage: result?.itemsPerPage ?? 10,
      count: result?.count ?? 0,
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
      final fresh = await _fetchPage(1);

      return fresh;
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

      final response = await api.getClientBookings(
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
          lastFetchedAt: DateTime.now(),
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
}
