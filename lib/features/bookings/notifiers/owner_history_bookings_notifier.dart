import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/bookings/providers/booking_mutation_provider.dart';
import 'package:prokat/features/bookings/state/booking_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/auth/providers/authenticated_session_scope.dart';

class OwnerHistoryBookingsNotifier
    extends AsyncNotifier<QueryState<BookingModel>> {
  BookingService get api => ref.read(bookingServiceProvider);
  Future<void>? _refreshing;
  AuthenticatedSessionScopeKey? _refreshingScope;
  AuthenticatedSessionScopeKey? _stateScope;

  @override
  Future<QueryState<BookingModel>> build() async {
    final scope = ref.watch(authenticatedSessionScopeKeyProvider);
    _stateScope = null;
    if (scope == null) {
      return const QueryState(itemsPerPage: 10, count: 0);
    }
    final next = await _fetchPage(1, scope);
    if (isAuthenticatedSessionScopeCurrent(ref, scope)) _stateScope = scope;
    return next;
  }

  Future<QueryState<BookingModel>> _fetchPage(
    int page,
    AuthenticatedSessionScopeKey scope,
  ) async {
    if (!isAuthenticatedSessionScopeCurrent(ref, scope)) {
      throw const UnauthenticatedSessionScopeException();
    }
    final response = await api.getOwnerBookings(
      page: page,
      itemsPerPage: 10,
      status: "HISTORY",
    );
    if (!isAuthenticatedSessionScopeCurrent(ref, scope)) {
      throw const UnauthenticatedSessionScopeException();
    }

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
    final previous = _stateScope == scope ? state.value : null;

    if (previous == null) {
      if (state.isLoading) {
        try {
          await future;
          if (!isAuthenticatedSessionScopeCurrent(ref, scope)) return;
          return;
        } catch (_) {}
      }
      if (!isAuthenticatedSessionScopeCurrent(ref, scope)) return;
      state = const AsyncLoading();
      _stateScope = null;
      final next = await AsyncValue.guard(() => _fetchPage(1, scope));
      if (isAuthenticatedSessionScopeCurrent(ref, scope)) {
        state = next;
        _stateScope = next is AsyncData<QueryState<BookingModel>>
            ? scope
            : null;
      }
      return;
    }

    if (!isAuthenticatedSessionScopeCurrent(ref, scope)) return;
    state = AsyncData(previous.copyWith(isRefreshing: true));
    try {
      final next = await _fetchPage(1, scope);
      if (isAuthenticatedSessionScopeCurrent(ref, scope)) {
        state = AsyncData(next);
        _stateScope = scope;
      }
    } catch (error) {
      if (isAuthenticatedSessionScopeCurrent(ref, scope)) {
        state = AsyncData(previous.withRefreshError(error));
      }
    }
  }

  Future<void> loadMore() async {
    final scope = readAuthenticatedSessionScope(ref);
    if (scope == null) return;

    final current = _stateScope == scope ? state.value : null;
    if (_stateScope != scope) return;

    if (current == null) return;

    if (!current.hasMore) return;

    if (current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final nextPage = current.page + 1;

      final response = await api.getOwnerBookings(
        page: nextPage,
        itemsPerPage: current.itemsPerPage,
        status: "HISTORY",
      );
      if (!isAuthenticatedSessionScopeCurrent(ref, scope)) return;

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
      if (isAuthenticatedSessionScopeCurrent(ref, scope)) {
        state = AsyncData(current.copyWith(isLoadingMore: false));
      }
    }
  }

  Future<void> invalidate() async {
    final current = state.value;

    if (current == null) return;

    state = AsyncData(current.copyWith(lastFetchedAt: () => null));
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
    final current = _stateScope == scope ? state.value : null;

    if (current == null) {
      await refresh();
      return;
    }

    if (current.isStale) {
      await refresh();
    }
  }
}
