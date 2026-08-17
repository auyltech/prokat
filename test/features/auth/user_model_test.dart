import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/auth/models/auth_session.dart';
import 'package:prokat/features/auth/models/user_model.dart';

void main() {
  test('AuthSession round-trip preserves user rating from persisted json', () {
    const session = AuthSession(
      sessionToken: 'session-token',
      user: UserModel(id: 'user-1', rating: 4),
    );

    final restored = AuthSession.fromJson(session.toJson());

    expect(restored.user?.rating, 4);
  });

  test('UserModel.fromJson accepts backend rating field', () {
    final user = UserModel.fromJson(const {
      'id': 'user-1',
      'rating': 5,
    });

    expect(user.rating, 5);
  });
}
