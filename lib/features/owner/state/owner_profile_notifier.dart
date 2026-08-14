import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/auth/providers/authenticated_session_scope.dart';
import 'package:prokat/features/owner/models/owner_profile_model.dart';
import 'package:prokat/features/owner/state/owner_registration_provider.dart';
import 'package:prokat/features/owner/state/owner_registration_service.dart';

class OwnerProfileNotifier extends AsyncNotifier<OwnerProfileModel?> {
  OwnerRegistrationService get api =>
      ref.read(ownerRegistrationServiceProvider);

  static const staleAfter = Duration(minutes: 5);
  DateTime? _lastFetchedAt;
  Future<void>? _refreshing;
  AuthenticatedSessionScopeKey? _refreshingScope;
  AuthenticatedSessionScopeKey? _stateScope;

  @override
  Future<OwnerProfileModel?> build() async {
    final scope = ref.watch(authenticatedSessionScopeKeyProvider);
    _stateScope = null;
    if (scope == null) return null;
    final next = await _fetch(scope);
    if (isAuthenticatedSessionScopeCurrent(ref, scope)) _stateScope = scope;
    return next;
  }

  Future<OwnerProfileModel?> _fetch(AuthenticatedSessionScopeKey scope) async {
    if (!isAuthenticatedSessionScopeCurrent(ref, scope)) {
      throw const UnauthenticatedSessionScopeException();
    }
    final profile = await api.getOwnerProfile();
    if (!isAuthenticatedSessionScopeCurrent(ref, scope)) {
      throw const UnauthenticatedSessionScopeException();
    }
    _lastFetchedAt = DateTime.now();
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
        _stateScope == scope && state is AsyncData<OwnerProfileModel?>;
    final previous = hadData ? state.value : null;
    if (!hadData && state.isLoading) {
      try {
        await future;
        if (!isAuthenticatedSessionScopeCurrent(ref, scope)) return;
        return;
      } catch (_) {}
    }
    if (!isAuthenticatedSessionScopeCurrent(ref, scope)) return;
    if (!hadData) {
      state = const AsyncLoading();
      _stateScope = null;
      final next = await AsyncValue.guard(() => _fetch(scope));
      if (isAuthenticatedSessionScopeCurrent(ref, scope)) {
        state = next;
        _stateScope = next is AsyncData<OwnerProfileModel?> ? scope : null;
      }
      return;
    }
    try {
      final next = await _fetch(scope);
      if (isAuthenticatedSessionScopeCurrent(ref, scope)) {
        state = AsyncData(next);
        _stateScope = scope;
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
    if (_stateScope != scope) {
      await refresh();
      return;
    }
    final fetchedAt = _lastFetchedAt;
    if (fetchedAt == null ||
        DateTime.now().difference(fetchedAt) > staleAfter) {
      await refresh();
    }
  }

  void invalidate() => _lastFetchedAt = null;
}
