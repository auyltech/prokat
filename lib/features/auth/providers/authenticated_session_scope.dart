import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';

class UnauthenticatedSessionScopeException implements Exception {
  const UnauthenticatedSessionScopeException();

  @override
  String toString() => 'Authenticated session is required';
}

/// Stable identity for in-memory state that must never cross user sessions.
///
/// The user id is preferred so a token refresh does not rebuild every
/// user-scoped provider. The token is only a fallback for incomplete legacy
/// sessions and is intentionally never exposed by [toString].
class AuthenticatedSessionScopeKey {
  final String _identity;
  final bool _usesUserId;
  final int _generation;

  const AuthenticatedSessionScopeKey.forUser(
    String userId, {
    int generation = 0,
  }) : _identity = userId,
       _usesUserId = true,
       _generation = generation;

  const AuthenticatedSessionScopeKey.forSessionToken(
    String sessionToken, {
    int generation = 0,
  }) : _identity = sessionToken,
       _usesUserId = false,
       _generation = generation;

  @override
  bool operator ==(Object other) {
    return other is AuthenticatedSessionScopeKey &&
        other._identity == _identity &&
        other._usesUserId == _usesUserId &&
        other._generation == _generation;
  }

  @override
  int get hashCode => Object.hash(_identity, _usesUserId, _generation);

  @override
  String toString() => _usesUserId
      ? 'AuthenticatedSessionScopeKey(user)'
      : 'AuthenticatedSessionScopeKey(session)';
}

final _authenticatedSessionScopeTrackerProvider =
    NotifierProvider<
      _AuthenticatedSessionScopeTracker,
      AuthenticatedSessionScopeKey?
    >(_AuthenticatedSessionScopeTracker.new);

final authenticatedSessionScopeKeyProvider =
    Provider<AuthenticatedSessionScopeKey?>((ref) {
      return ref.watch(_authenticatedSessionScopeTrackerProvider);
    });

class _AuthenticatedSessionScopeTracker
    extends Notifier<AuthenticatedSessionScopeKey?> {
  int _generation = 0;
  String? _previousIdentity;
  bool? _previousUsesUserId;
  bool _wasAuthenticated = false;

  @override
  AuthenticatedSessionScopeKey? build() {
    final session = ref.watch(authProvider.select((auth) => auth.session));
    if (session == null) {
      _wasAuthenticated = false;
      return null;
    }

    final userId = session.user?.id?.trim();
    final token = session.sessionToken?.trim();
    final usesUserId = userId != null && userId.isNotEmpty;
    final identity = usesUserId ? userId : token;
    if (identity == null || identity.isEmpty) {
      _wasAuthenticated = false;
      return null;
    }

    if (!_wasAuthenticated ||
        identity != _previousIdentity ||
        usesUserId != _previousUsesUserId) {
      _generation++;
    }

    _wasAuthenticated = true;
    _previousIdentity = identity;
    _previousUsesUserId = usesUserId;

    return usesUserId
        ? AuthenticatedSessionScopeKey.forUser(
            identity,
            generation: _generation,
          )
        : AuthenticatedSessionScopeKey.forSessionToken(
            identity,
            generation: _generation,
          );
  }
}

AuthenticatedSessionScopeKey? readAuthenticatedSessionScope(Ref ref) {
  return ref.read(authenticatedSessionScopeKeyProvider);
}

bool isAuthenticatedSessionScopeCurrent(
  Ref ref,
  AuthenticatedSessionScopeKey scope,
) {
  return ref.read(authenticatedSessionScopeKeyProvider) == scope;
}
