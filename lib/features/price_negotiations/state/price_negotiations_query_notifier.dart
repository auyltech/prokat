import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_model.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_query.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_provider.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_service.dart';

class PriceNegotiationsNotifier
    extends
        FamilyAsyncNotifier<
          QueryState<PriceNegotiation>,
          PriceNegotiationQuery
        > {
  late final PriceNegotiationService service;
  late final PriceNegotiationQuery query;
  Future<void>? _refreshing;

  @override
  Future<QueryState<PriceNegotiation>> build(PriceNegotiationQuery arg) async {
    service = ref.read(priceNegotiationServiceProvider);
    query = arg;
    return _fetchPage(1);
  }

  Future<QueryState<PriceNegotiation>> _fetchPage(int page) async {
    final response = await service.getPriceNegotiations(
      query: query,
      page: page,
    );
    final result = response.data;
    if (!response.success || result == null) throw Exception(response.message);
    return QueryState(
      items: _sortAndDedupe(result.items),
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

  Future<void> refreshIfStale() async {
    if (state.isLoading) {
      try {
        await future;
      } catch (_) {}
    }
    final current = state.value;
    if (current == null || current.isStale) await refresh();
  }

  Future<void> invalidate() async {
    final current = state.value;
    if (current != null) {
      state = AsyncData(current.copyWith(lastFetchedAt: () => null));
    }
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final next = await _fetchPage(current.page + 1);
      state = AsyncData(
        current.copyWith(
          items: _sortAndDedupe([...current.items, ...next.items]),
          page: next.page,
          itemsPerPage: next.itemsPerPage,
          count: next.count,
          lastFetchedAt: DateTime.now,
          isLoadingMore: false,
          refreshError: () => null,
        ),
      );
    } catch (error) {
      state = AsyncData(
        current.copyWith(isLoadingMore: false).withRefreshError(error),
      );
    }
  }

  List<PriceNegotiation> _sortAndDedupe(List<PriceNegotiation> values) {
    final byId = {for (final value in values) value.id: value};
    final result = byId.values.toList();
    result.sort((a, b) {
      final date = (b.createdAt ?? DateTime(0)).compareTo(
        a.createdAt ?? DateTime(0),
      );
      return date != 0 ? date : b.id.compareTo(a.id);
    });
    return result;
  }
}
