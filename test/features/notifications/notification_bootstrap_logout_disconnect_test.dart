import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/providers/socket_provider.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:prokat/features/auth/models/auth_session.dart';
import 'package:prokat/features/auth/providers/auth_api_service.dart';
import 'package:prokat/features/auth/providers/auth_notifier.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/auth/providers/auth_secure_storage.dart';
import 'package:prokat/features/auth/providers/auth_state.dart';
import 'package:prokat/features/notifications/providers/notification_bootstrap_provider.dart';
import 'package:prokat/features/notifications/providers/notification_navigation_service_provider.dart';
import 'package:prokat/features/notifications/services/notification_local_storage.dart';

import '../../support/fake_app_socket_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test(
    'logout with notification bootstrap disconnects the app socket once',
    () async {
      late FakeAppSocketService appSocket;
      final storage = NotificationLocalStorage();
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(_authenticatedAuthNotifier),
          appSocketProvider.overrideWith((ref) {
            appSocket = FakeAppSocketService(ref);
            return appSocket;
          }),
          notificationLocalStorageProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(container.dispose);

      container.read(appStartupProvider);
      container.read(notificationBootstrapProvider);

      await _forceSignedOut(container);

      expect(appSocket.disconnectCalls, 1);
      expect(container.read(authProvider).session, isNull);
    },
  );
}

Future<void> _forceSignedOut(ProviderContainer container) {
  final pending = container.read(appStartupProvider.notifier).forceSignedOut();
  return _pumpScheduledFrame().then((_) => pending);
}

Future<void> _pumpScheduledFrame() async {
  await Future<void>.delayed(Duration.zero);
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  binding.handleBeginFrame(Duration.zero);
  binding.handleDrawFrame();
}

AuthNotifier _authenticatedAuthNotifier(Ref ref) {
  return _LocalLogoutAuthNotifier(ref);
}

class _LocalLogoutAuthNotifier extends AuthNotifier {
  _LocalLogoutAuthNotifier(Ref ref)
    : super(ref, AuthApiService(Dio()), AuthSecureStorage()) {
    state = const AuthState(
      session: AuthSession(sessionToken: 'session-user-a'),
    );
  }

  @override
  Future<void> logout() async {
    await clearLocalSession();
  }
}
