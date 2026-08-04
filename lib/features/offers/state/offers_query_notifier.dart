import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/offers/models/offer_model.dart';
import 'package:prokat/features/offers/models/offer_query.dart';
import 'package:prokat/features/offers/state/offers_provider.dart';
import 'package:prokat/features/offers/state/offers_service.dart';

abstract class OffersQueryNotifier
    extends FamilyAsyncNotifier<QueryState<OfferModel>, OfferQuery> {
  bool get isOwner;

  late final OffersService service;
  late final OfferQuery query;
  Future<void>? _refreshing;

  @override
  Future<QueryState<OfferModel>> build(OfferQuery arg) async {
    service = ref.read(offersServiceProvider);
    query = arg;
    return _fetchPage(1);
  }

  Future<QueryState<OfferModel>> _fetchPage(int page) async {
    final response = isOwner
        ? await service.getOwnerOffers(
            page: page,
            itemsPerPage: query.itemsPerPage,
            filter: query.filter,
            requestId: query.requestId,
          )
        : await service.getClientOffers(
            page: page,
            itemsPerPage: query.itemsPerPage,
            filter: query.filter,
            requestId: query.requestId,
          );
    final result = response.data;
    if (!response.success || result == null) throw Exception(response.message);

    final items = _sortAndDedupe(result.items);
    return QueryState(
      items: items,
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
    if (current == null) return;
    state = AsyncData(current.copyWith(lastFetchedAt: () => null));
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

  List<OfferModel> _sortAndDedupe(List<OfferModel> values) {
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

class ClientOffersNotifier extends OffersQueryNotifier {
  @override
  bool get isOwner => false;
}

class OwnerOffersNotifier extends OffersQueryNotifier {
  @override
  bool get isOwner => true;
}
