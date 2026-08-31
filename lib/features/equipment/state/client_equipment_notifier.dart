import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/providers/locale_provider.dart';
import 'package:prokat/features/auth/providers/authenticated_session_scope.dart';
import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/providers/equipment_dependencies.dart';
import 'package:prokat/features/equipment/state/equipment_service.dart';
import 'package:prokat/features/locations/state/location_provider.dart';

class ClientEquipmentNotifier extends AsyncNotifier<QueryState<Equipment>> {
  EquipmentService get api => ref.read(equipmentServiceProvider);
  Future<void>? _refreshing;
  int? _refreshingGeneration;
  AuthenticatedSessionScopeKey? _refreshingScope;
  AuthenticatedSessionScopeKey? _stateScope;
  AuthenticatedSessionScopeKey? _filterScope;
  int _requestGeneration = 0;

  String? _query;
  String? _city;
  String? _categoryId;
  List<String> _spec = const [];

  static const _itemsPerPage = 10;

  @override
  Future<QueryState<Equipment>> build() async {
    final scope = ref.watch(authenticatedSessionScopeKeyProvider);
    final city = ref.watch(locationProvider.select((s) => s.city));
    _stateScope = null;
    if (_filterScope != scope) {
      _filterScope = scope;
      _query = null;
      _categoryId = null;
      _spec = const [];
      _requestGeneration++;
    }
    _city = city;
    if (scope == null) {
      return const QueryState(itemsPerPage: _itemsPerPage, count: 0);
    }
    final next = await _fetchPage(1, scope);
    if (isAuthenticatedSessionScopeCurrent(ref, scope)) _stateScope = scope;
    return next;
  }

  Future<QueryState<Equipment>> _fetchPage(
    int page,
    AuthenticatedSessionScopeKey scope,
  ) async {
    if (!isAuthenticatedSessionScopeCurrent(ref, scope)) {
      throw const UnauthenticatedSessionScopeException();
    }
    final locale = ref.read(localeProvider).languageCode.toUpperCase();
    final response = await api.getClientEquipment(
      locale: locale,
      page: page,
      itemsPerPage: _itemsPerPage,
      query: _query,
      city: _city,
      categoryId: _categoryId,
      spec: _spec,
    );
    if (!isAuthenticatedSessionScopeCurrent(ref, scope)) {
      throw const UnauthenticatedSessionScopeException();
    }

    if (!response.success) {
      throw Exception(response.message);
    }

    final items = response.data ?? [];
    final total = response.count;

    return QueryState(
      items: items,
      page: page,
      itemsPerPage: _itemsPerPage,
      count:
          total ??
          (items.length < _itemsPerPage
              ? ((page - 1) * _itemsPerPage) + items.length
              : (page * _itemsPerPage) + 1),
      lastFetchedAt: DateTime.now(),
    );
  }

  Future<void> refresh() {
    final scope = readAuthenticatedSessionScope(ref);
    if (scope == null) return Future<void>.value();
    return _refreshForGeneration(_requestGeneration, scope);
  }

  Future<void> _refreshForGeneration(
    int generation,
    AuthenticatedSessionScopeKey scope,
  ) {
    final active = _refreshing;
    if (active != null &&
        _refreshingGeneration == generation &&
        _refreshingScope == scope) {
      return active;
    }

    final operation = _refresh(generation, scope);
    _refreshing = operation;
    _refreshingGeneration = generation;
    _refreshingScope = scope;
    return operation.whenComplete(() {
      if (identical(_refreshing, operation)) {
        _refreshing = null;
        _refreshingGeneration = null;
        _refreshingScope = null;
      }
    });
  }

  Future<void> _refresh(
    int generation,
    AuthenticatedSessionScopeKey scope,
  ) async {
    if (state.isLoading &&
        (_stateScope != scope || state.valueOrNull == null)) {
      try {
        await future;
      } catch (_) {}
      if (!_isRequestCurrent(generation, scope)) return;
    }

    final previous = _stateScope == scope ? state.valueOrNull : null;

    if (previous == null) {
      if (!_isRequestCurrent(generation, scope)) return;
      state = const AsyncLoading();
      _stateScope = null;
      final next = await AsyncValue.guard(() => _fetchPage(1, scope));
      if (_isRequestCurrent(generation, scope)) {
        state = next;
        _stateScope = next is AsyncData<QueryState<Equipment>> ? scope : null;
      }
      return;
    }

    if (!_isRequestCurrent(generation, scope)) return;
    state = AsyncData(previous.copyWith(isRefreshing: true));
    try {
      final next = await _fetchPage(1, scope);
      if (_isRequestCurrent(generation, scope)) {
        state = AsyncData(next);
        _stateScope = scope;
      }
    } catch (error) {
      if (_isRequestCurrent(generation, scope)) {
        state = AsyncData(previous.withRefreshError(error));
      }
    }
  }

  Future<void> loadMore() async {
    final scope = readAuthenticatedSessionScope(ref);
    if (scope == null) return;

    final current = _stateScope == scope ? state.valueOrNull : null;
    final generation = _requestGeneration;
    if (_stateScope != scope) return;

    if (current == null) return;

    if (!current.hasMore) return;

    if (current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final nextPage = current.page + 1;

      final locale = ref.read(localeProvider).languageCode.toUpperCase();
      final response = await api.getClientEquipment(
        locale: locale,
        page: nextPage,
        itemsPerPage: current.itemsPerPage,
        query: _query,
        city: _city,
        categoryId: _categoryId,
        spec: _spec,
      );

      if (!_isRequestCurrent(generation, scope)) return;

      if (!response.success || response.data == null) {
        state = AsyncData(current.copyWith(isLoadingMore: false));
        return;
      }

      final items = response.data!;
      final total = response.count;

      state = AsyncData(
        current.copyWith(
          items: [...current.items, ...items],
          page: nextPage,
          count:
              total ??
              (items.length < current.itemsPerPage
                  ? current.items.length + items.length
                  : current.count + current.itemsPerPage),
          lastFetchedAt: DateTime.now,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      if (_isRequestCurrent(generation, scope)) {
        state = AsyncData(current.copyWith(isLoadingMore: false));
      }
    }
  }

  Future<void> search({
    String? query,
    String? city,
    String? categoryId,
    List<String>? spec,
  }) async {
    final scope = readAuthenticatedSessionScope(ref);
    if (scope == null) return;

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
    await _refreshForGeneration(generation, scope);
  }

  Future<void> clearSearch() async {
    final scope = readAuthenticatedSessionScope(ref);
    if (scope == null) return;

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
      await _refreshForGeneration(generation, scope);
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
    final scope = readAuthenticatedSessionScope(ref);
    if (scope == null) return;

    if (state.isLoading) {
      try {
        await future;
      } catch (_) {}
    }
    if (!isAuthenticatedSessionScopeCurrent(ref, scope)) return;
    final current = _stateScope == scope ? state.valueOrNull : null;

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

  bool _isRequestCurrent(int generation, AuthenticatedSessionScopeKey scope) {
    return generation == _requestGeneration &&
        isAuthenticatedSessionScopeCurrent(ref, scope);
  }

  bool _sameSpec(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (var i = 0; i < left.length; i++) {
      if (left[i] != right[i]) return false;
    }
    return true;
  }
}
