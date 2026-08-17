import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/providers/equipment_dependencies.dart';
import 'package:prokat/features/equipment/state/equipment_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/auth/providers/authenticated_session_scope.dart';

class OwnerEquipmentNotifier extends AsyncNotifier<QueryState<Equipment>> {
  EquipmentService get api => ref.read(equipmentServiceProvider);
  Future<void>? _refreshing;
  AuthenticatedSessionScopeKey? _refreshingScope;
  AuthenticatedSessionScopeKey? _stateScope;

  @override
  Future<QueryState<Equipment>> build() async {
    final scope = ref.watch(authenticatedSessionScopeKeyProvider);
    _stateScope = null;
    if (scope == null) {
      return const QueryState(itemsPerPage: 1, count: 0);
    }
    final next = await _fetch(scope);
    if (isAuthenticatedSessionScopeCurrent(ref, scope)) _stateScope = scope;
    return next;
  }

  Future<QueryState<Equipment>> _fetch(
    AuthenticatedSessionScopeKey scope,
  ) async {
    if (!isAuthenticatedSessionScopeCurrent(ref, scope)) {
      throw const UnauthenticatedSessionScopeException();
    }
    final response = await api.getOwnerEquipment();
    if (!isAuthenticatedSessionScopeCurrent(ref, scope)) {
      throw const UnauthenticatedSessionScopeException();
    }

    if (!response.success) {
      throw Exception(response.message);
    }

    final items = response.data ?? [];

    items.sort(_compareEquipment);

    return QueryState(
      items: items,
      page: 1,
      itemsPerPage: items.isEmpty ? 1 : items.length,
      count: items.length,
      lastFetchedAt: DateTime.now(),
    );
  }

  int _statusPriority(EquipmentStatus status) {
    switch (status) {
      case EquipmentStatus.available:
        return 0;
      case EquipmentStatus.booked:
        return 1;
      case EquipmentStatus.maintenance:
        return 2;
      default:
        return 99;
    }
  }

  int _compareEquipment(Equipment a, Equipment b) {
    final aOnline = a.isVisible ? 0 : 1;
    final bOnline = b.isVisible ? 0 : 1;

    if (aOnline != bOnline) {
      return aOnline.compareTo(bOnline);
    }

    final statusCompare = _statusPriority(
      a.status,
    ).compareTo(_statusPriority(b.status));

    if (statusCompare != 0) {
      return statusCompare;
    }

    return (b.updatedAt ?? DateTime(0)).compareTo(a.updatedAt ?? DateTime(0));
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
      final next = await AsyncValue.guard(() => _fetch(scope));
      if (isAuthenticatedSessionScopeCurrent(ref, scope)) {
        state = next;
        _stateScope = next is AsyncData<QueryState<Equipment>> ? scope : null;
      }
      return;
    }

    if (!isAuthenticatedSessionScopeCurrent(ref, scope)) return;
    state = AsyncData(previous.copyWith(isRefreshing: true));
    try {
      final next = await _fetch(scope);
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

  Future<void> invalidate() async {
    final scope = readAuthenticatedSessionScope(ref);
    if (scope == null) return;
    final current = _stateScope == scope ? state.value : null;

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

  Equipment? findById(String id) {
    final scope = readAuthenticatedSessionScope(ref);
    final items = scope != null && _stateScope == scope
        ? state.value?.items ?? const []
        : const <Equipment>[];

    for (final equipment in items) {
      if (equipment.id == id) {
        return equipment;
      }
    }

    return null;
  }

  int get onlineEquipmentCount {
    final scope = readAuthenticatedSessionScope(ref);
    final items = scope != null && _stateScope == scope
        ? state.value?.items ?? const []
        : const <Equipment>[];
    return items.where((item) => item.isVisible).length;
  }

  Future<void> replaceItem(
    String equipmentId,
    Equipment Function(Equipment current) builder,
  ) async {
    final scope = readAuthenticatedSessionScope(ref);
    if (scope == null) return;
    final current = _stateScope == scope ? state.value : null;

    if (current == null) return;

    final items = current.items.map((item) {
      if (item.id != equipmentId) return item;

      return builder(item);
    }).toList();

    state = AsyncData(current.copyWith(items: items));
  }
}
