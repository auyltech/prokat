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
    final user = UserModel.fromJson(const {'id': 'user-1', 'rating': 5});

    expect(user.rating, 5);
  });

  test('displayName uses given name, not phone', () {
    const user = UserModel(
      firstName: 'Алия',
      lastName: 'Нурланова',
      phoneNumber: '+77052222222',
    );

    expect(user.displayName, 'Алия Нурланова');
  });

  test('displayName uses username when name is empty', () {
    const user = UserModel(
      username: 'atyrau_owner',
      phoneNumber: '+77052222222',
    );

    expect(user.displayName, 'atyrau_owner');
  });

  test('displayName does not fall back to phone', () {
    const user = UserModel(phoneNumber: '+77052222222');

    expect(user.displayName, isEmpty);
    expect(user.displayNameOr('Name not specified'), 'Name not specified');
  });

  test('UserModel.fromJson accepts backend ratingAverage as a double', () {
    final user = UserModel.fromJson(const {
      'id': 'user-1',
      'ratingAverage': 4.5,
    });

    expect(user.rating, 5);
  });

  test('displayName uses companyName when personal name is empty', () {
    const user = UserModel(
      companyName: 'Atyrau Vac',
      phoneNumber: '+77052222222',
    );

    expect(user.displayName, 'Atyrau Vac');
  });
}
