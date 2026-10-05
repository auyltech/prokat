import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/analytics/analytics_identity.dart';
import 'package:prokat/core/analytics/analytics_service.dart';
import 'package:prokat/core/analytics/pending_sign_up.dart';
import 'package:prokat/features/auth/models/auth_session.dart';
import 'package:prokat/features/auth/models/user_model.dart';
import 'package:prokat/features/auth/providers/auth_api_service.dart';
import 'package:prokat/features/auth/providers/auth_notifier.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/auth/providers/auth_secure_storage.dart';
import 'package:prokat/features/auth/providers/auth_state.dart';
import 'package:prokat/features/user/models/user_profile_model.dart';
import 'package:prokat/features/user/state/client_profile_notifier.dart';
import 'package:prokat/features/user/state/client_profile_provider.dart';

import '../../helpers/recording_analytics_client.dart';

void main() {
  group('resolveAnalyticsIdentity', () {
    test('guest resolves to null identity', () {
      final identity = resolveAnalyticsIdentity(
        userId: null,
        jwtIsOwner: true,
        profileRole: 'OWNER',
      );

      expect(identity, const AnalyticsIdentity());
      expect(identity.userId, isNull);
      expect(identity.role, isNull);
    });

    test('client role', () {
      expect(
        resolveAnalyticsIdentity(
          userId: 'user-1',
          jwtIsOwner: false,
          profileRole: 'CLIENT',
        ),
        const AnalyticsIdentity(userId: 'user-1', role: 'client'),
      );
    });

    test('jwt owner wins over stale profile client', () {
      expect(
        resolveAnalyticsIdentity(
          userId: 'user-1',
          jwtIsOwner: true,
          profileRole: 'CLIENT',
        ),
        const AnalyticsIdentity(userId: 'user-1', role: 'owner'),
      );
    });

    test('profile owner wins over stale jwt client', () {
      expect(
        resolveAnalyticsIdentity(
          userId: 'user-1',
          jwtIsOwner: false,
          profileRole: 'OWNER',
        ),
        const AnalyticsIdentity(userId: 'user-1', role: 'owner'),
      );
    });

    test('admin maps to owner', () {
      expect(
        resolveAnalyticsIdentity(
          userId: 'user-1',
          jwtIsOwner: false,
          profileRole: 'ADMIN',
        ),
        const AnalyticsIdentity(userId: 'user-1', role: 'owner'),
      );
    });

    test('unknown profile role maps to client', () {
      expect(
        resolveAnalyticsIdentity(
          userId: 'user-1',
          jwtIsOwner: false,
          profileRole: 'MODERATOR',
        ).role,
        'client',
      );
    });

    test('identities with equal fields are equal', () {
      expect(
        const AnalyticsIdentity(userId: 'user-1', role: 'client'),
        const AnalyticsIdentity(userId: 'user-1', role: 'client'),
      );
      expect(
        const AnalyticsIdentity(userId: 'user-1', role: 'client').hashCode,
        const AnalyticsIdentity(userId: 'user-1', role: 'client').hashCode,
      );
      expect(
        const AnalyticsIdentity(userId: 'user-1', role: 'client'),
        isNot(const AnalyticsIdentity(userId: 'user-1', role: 'owner')),
      );
    });
  });

  group('analyticsIdentityBootstrapProvider', () {
    late RecordingAnalyticsClient client;
    late _TestAuthNotifier auth;
    late _TestClientProfileNotifier profile;
    late ProviderContainer container;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      client = RecordingAnalyticsClient();
      container = ProviderContainer(
        overrides: [
          analyticsServiceProvider.overrideWithValue(AnalyticsService(client)),
          authProvider.overrideWith((ref) => auth = _TestAuthNotifier(ref)),
          clientProfileProvider.overrideWith(
            () => profile = _TestClientProfileNotifier(),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.read(analyticsIdentityBootstrapProvider);
    });

    test('guest sends null identity on start', () async {
      await _settle();

      expect(client.userIds, [null]);
      expect(client.userProperties.map((e) => (e.key, e.value)), [
        ('user_role', null),
      ]);
    });

    test('authenticated client sets user id and client role', () async {
      await _settle();
      auth.setUser(const UserModel(id: 'user-1', role: UserRole.client));
      await _settle();

      expect(client.userIds.last, 'user-1');
      expect(client.userProperties.last.key, 'user_role');
      expect(client.userProperties.last.value, 'client');
    });

    test('owner sets owner role', () async {
      await _settle();
      auth.setUser(const UserModel(id: 'user-1', role: UserRole.owner));
      await _settle();

      expect(client.userIds.last, 'user-1');
      expect(client.userProperties.last.value, 'owner');
    });

    test('profile refresh to owner updates role', () async {
      await _settle();
      auth.setUser(const UserModel(id: 'user-1', role: UserRole.client));
      await _settle();
      profile.setRole('OWNER');
      await _settle();

      expect(client.userIds.last, 'user-1');
      expect(client.userProperties.last.value, 'owner');
    });

    test('logout clears identity', () async {
      await _settle();
      auth.setUser(const UserModel(id: 'user-1', role: UserRole.client));
      await _settle();
      auth.setUser(null);
      await _settle();

      expect(client.userIds.last, isNull);
      expect(client.userProperties.last.key, 'user_role');
      expect(client.userProperties.last.value, isNull);
    });

    test('account change A to B sets the latest user id', () async {
      await _settle();
      auth.setUser(const UserModel(id: 'user-a', role: UserRole.owner));
      await _settle();
      auth.setUser(const UserModel(id: 'user-b', role: UserRole.client));
      await _settle();

      expect(client.userIds.last, 'user-b');
      expect(client.userProperties.last.value, 'client');
    });

    test('pending sign_up is sent once after identity changes again', () async {
      await _settle();
      container.read(pendingSignUpProvider).markPending('user-1');
      auth.setUser(const UserModel(id: 'user-1', role: UserRole.client));
      await _settle();
      profile.setRole('OWNER');
      await _settle();
      auth.setUser(
        const UserModel(id: 'user-1', role: UserRole.client, firstName: 'X'),
      );
      await _settle();

      expect(client.events.map((e) => e.name), ['sign_up']);
      expect(client.userProperties.last.value, 'owner');
    });

    test('logout does not send sign_up', () async {
      await _settle();
      auth.setUser(const UserModel(id: 'user-1', role: UserRole.client));
      await _settle();
      container.read(pendingSignUpProvider).markPending('user-2');
      auth.setUser(null);
      await _settle();

      expect(client.userIds.last, isNull);
      expect(client.userProperties.last.value, isNull);
      expect(client.events, isEmpty);
    });

    test('pending sign_up for A is not sent for B', () async {
      await _settle();
      container.read(pendingSignUpProvider).markPending('user-a');
      auth.setUser(const UserModel(id: 'user-b', role: UserRole.client));
      await _settle();

      expect(client.userIds.last, 'user-b');
      expect(client.events, isEmpty);
    });

    test('unchanged identity is not sent again', () async {
      await _settle();
      auth.setUser(const UserModel(id: 'user-1', role: UserRole.client));
      await _settle();
      final calls = client.userIds.length;

      auth.setUser(
        const UserModel(
          id: 'user-1',
          role: UserRole.client,
          firstName: 'Renamed',
        ),
      );
      await _settle();

      expect(client.userIds.length, calls);
    });
  });
}

Future<void> _settle() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier(Ref ref)
    : super(ref, AuthApiService(Dio()), AuthSecureStorage());

  void setUser(UserModel? user) {
    state = user == null
        ? const AuthState()
        : AuthState(
            session: AuthSession(sessionToken: 'token-${user.id}', user: user),
          );
  }
}

class _TestClientProfileNotifier extends ClientProfileNotifier {
  @override
  Future<UserProfileModel?> build() async => null;

  void setRole(String role) {
    state = AsyncData(UserProfileModel(role: role));
  }
}
