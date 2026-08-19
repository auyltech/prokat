import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/auth/providers/authenticated_session_scope.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/features/user/models/user_profile_model.dart';
import 'package:prokat/features/user/state/client_profile_provider.dart';
import 'package:prokat/features/user/state/client_profile_service.dart';

class ClientProfileNotifier extends AsyncNotifier<UserProfileModel?> {
  ClientProfileService get api => ref.read(clientProfileServiceProvider);

  static const staleAfter = Duration(minutes: 5);

  DateTime? _lastFetchedAt;
  Future<void>? _refreshing;
  AuthenticatedSessionScopeKey? _refreshingScope;
  AuthenticatedSessionScopeKey? _stateScope;

  @override
  Future<UserProfileModel?> build() async {
    final scope = ref.watch(authenticatedSessionScopeKeyProvider);
    if (scope == null) {
      _lastFetchedAt = null;
      _stateScope = null;
      return null;
    }

    final next = await _fetch(scope);
    if (!isAuthenticatedSessionScopeCurrent(ref, scope)) return null;
    _stateScope = scope;
    return next;
  }

  Future<UserProfileModel?> _fetch(AuthenticatedSessionScopeKey scope) async {
    final profile = await api.getUserProfile();
    if (!isAuthenticatedSessionScopeCurrent(ref, scope)) return null;

    _lastFetchedAt = DateTime.now();
    if (profile != null) {
      ref.read(locationProvider.notifier).selectCity(profile.city ?? '');
      ref
          .read(locationProvider.notifier)
          .selectAddressById(profile.selectedAddressId);
    }
    return profile;
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
    final hadData =
        _stateScope == scope && state is AsyncData<UserProfileModel?>;
    final previous = hadData ? state.value : null;
    if (!hadData && state.isLoading) {
      try {
        await future;
        return;
      } catch (_) {}
    }

    if (!hadData) {
      state = const AsyncLoading();
      final next = await AsyncValue.guard(() => _fetch(scope));
      if (isAuthenticatedSessionScopeCurrent(ref, scope)) {
        _stateScope = scope;
        state = next;
      }
      return;
    }

    try {
      final next = await _fetch(scope);
      if (isAuthenticatedSessionScopeCurrent(ref, scope)) {
        _stateScope = scope;
        state = AsyncData(next);
      }
    } catch (_) {
      if (isAuthenticatedSessionScopeCurrent(ref, scope)) {
        state = AsyncData(previous);
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
    final fetchedAt = _lastFetchedAt;
    if (_stateScope != scope ||
        fetchedAt == null ||
        DateTime.now().difference(fetchedAt) > staleAfter) {
      await refresh();
    }
  }

  void invalidate() => _lastFetchedAt = null;
}
