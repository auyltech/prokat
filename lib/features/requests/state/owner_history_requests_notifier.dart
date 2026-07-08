import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/requests/models/request_model.dart';
import 'package:prokat/features/requests/state/request_provider.dart';
import 'package:prokat/features/requests/state/request_service.dart';
import 'package:riverpod/riverpod.dart';

class OwnerHistoryRequestsNotifier
    extends AsyncNotifier<QueryState<RequestModel>> {
  late final RequestService api;

  @override
  Future<QueryState<RequestModel>> build() async {
    api = ref.read(requestServiceProvider);

    return _fetchPage(1);
  }

  Future<QueryState<RequestModel>> _fetchPage(int page) async {
    final response = await api.getOwnerRequests(
      page: page,
      itemsPerPage: 10,
      status: "HISTORY",
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

      final response = await api.getOwnerRequests(
        page: nextPage,
        itemsPerPage: current.itemsPerPage,
        status: "HISTORY",
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
