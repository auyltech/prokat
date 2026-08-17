import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/auth/models/auth_session.dart';
import 'package:prokat/features/auth/providers/auth_state.dart';

void main() {
  const session = AuthSession(sessionToken: 'session-token');

  group('AuthState.copyWith', () {
    test('retains session when it is omitted', () {
      const state = AuthState(session: session, isLoading: true);

      final updated = state.copyWith(isLoading: false);

      expect(updated.session, same(session));
      expect(updated.isLoading, isFalse);
    });

    test('clears session when null is passed explicitly', () {
      const state = AuthState(session: session);

      final updated = state.copyWith(session: null);

      expect(updated.session, isNull);
      expect(updated.isAuthenticated, isFalse);
    });
  });
}
