import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/auth/providers/authenticated_session_scope.dart';
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
  PriceNegotiationService get api => ref.read(priceNegotiationServiceProvider);

  late PriceNegotiationQuery query;
  Future<void>? _refreshing;
  AuthenticatedSessionScopeKey? _refreshingScope;
  AuthenticatedSessionScopeKey? _stateScope;

  @override
  Future<QueryState<PriceNegotiation>> build(PriceNegotiationQuery arg) async {
    query = arg;
    final scope = ref.watch(authenticatedSessionScopeKeyProvider);
    if (scope == null) {
      _stateScope = null;
      return _emptyState;
    }

    final next = await _fetchPage(1, scope);
    if (!isAuthenticatedSessionScopeCurrent(ref, scope)) return _emptyState;
    _stateScope = scope;
    return next;
  }

  Future<QueryState<PriceNegotiation>> _fetchPage(
    int page,
    AuthenticatedSessionScopeKey scope,
  ) async {
    if (!isAuthenticatedSessionScopeCurrent(ref, scope)) return _emptyState;

    final response = await api.getPriceNegotiations(query: query, page: page);
    if (!isAuthenticatedSessionScopeCurrent(ref, scope)) return _emptyState;

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
    final scope = readAuthenticatedSessionScope(ref);
    if (scope == null) return Future<void>.value();

    final active = _refreshing;
    if (active != null && _refreshingScope == scope) return active;

    final operation = _refresh(scope);
    _refreshing = operation;
    _refreshingScope = scope;
    return operation.whenComplete(() {
      if (identical(_refreshing, operation)) {
        _refreshing = null;
        _refreshingScope = null;
      }
    });
  }

  Future<void> _refresh(AuthenticatedSessionScopeKey scope) async {
    if (!isAuthenticatedSessionScopeCurrent(ref, scope)) return;

    if (state.isLoading) {
      try {
        await future;
        return;
      } catch (_) {}
      if (!isAuthenticatedSessionScopeCurrent(ref, scope)) return;
    }

    final previous = _stateScope == scope ? state.value : null;
    if (previous == null) {
      state = const AsyncLoading();
      final next = await AsyncValue.guard(() => _fetchPage(1, scope));
      if (isAuthenticatedSessionScopeCurrent(ref, scope)) {
        _stateScope = scope;
        state = next;
      }
      return;
    }
    state = AsyncData(previous.copyWith(isRefreshing: true));
    try {
      final next = await _fetchPage(1, scope);
      if (isAuthenticatedSessionScopeCurrent(ref, scope)) {
        _stateScope = scope;
        state = AsyncData(next);
      }
    } catch (error) {
      if (isAuthenticatedSessionScopeCurrent(ref, scope)) {
        state = AsyncData(previous.withRefreshError(error));
      }
    }
  }

  Future<void> refreshIfStale() async {
    final scope = readAuthenticatedSessionScope(ref);
    if (scope == null) return;

    if (state.isLoading) {
      try {
        await future;
      } catch (_) {}
    }
    if (!isAuthenticatedSessionScopeCurrent(ref, scope)) return;
    final current = state.value;
    if (_stateScope != scope || current == null || current.isStale) {
      await refresh();
    }
  }

  Future<void> invalidate() async {
    final scope = readAuthenticatedSessionScope(ref);
    if (scope == null || _stateScope != scope) return;
    final current = state.value;
    if (current != null) {
      state = AsyncData(current.copyWith(lastFetchedAt: () => null));
    }
  }

  Future<void> loadMore() async {
    final scope = readAuthenticatedSessionScope(ref);
    if (scope == null || _stateScope != scope) return;

    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final next = await _fetchPage(current.page + 1, scope);
      if (!isAuthenticatedSessionScopeCurrent(ref, scope)) return;
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
      if (isAuthenticatedSessionScopeCurrent(ref, scope)) {
        state = AsyncData(
          current.copyWith(isLoadingMore: false).withRefreshError(error),
        );
      }
    }
  }

  QueryState<PriceNegotiation> get _emptyState =>
      QueryState(itemsPerPage: query.itemsPerPage, count: 0);

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
