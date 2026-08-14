import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/providers/unauthorized_signal_provider.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:prokat/features/auth/models/auth_session.dart';
import 'package:prokat/features/auth/providers/auth_api_service.dart';
import 'package:prokat/features/auth/providers/auth_notifier.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/auth/providers/auth_secure_storage.dart';
import 'package:prokat/features/auth/providers/auth_state.dart';

void main() {
  test('one unauthorized signal starts one forced sign-out', () async {
    final signOutRelease = Completer<void>();
    late _RecordingAppStartupController controller;
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(_authenticatedAuthNotifier),
        appStartupProvider.overrideWith((ref) {
          controller = _RecordingAppStartupController(ref, signOutRelease);
          return controller;
        }),
      ],
    );
    addTearDown(() {
      if (!signOutRelease.isCompleted) signOutRelease.complete();
      container.dispose();
    });

    container.read(appStartupProvider);
    container.read(unauthorizedSignalProvider.notifier).state++;

    await _waitForSignOutCalls(controller, 1);

    expect(controller.signOutCalls, 1);
    expect(controller.unauthorizedArguments, [true]);

    signOutRelease.complete();
    await controller.lastSignOutCall;
  });

  test('concurrent unauthorized signals share one forced sign-out', () async {
    final signOutRelease = Completer<void>();
    late _RecordingAppStartupController controller;
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(_authenticatedAuthNotifier),
        appStartupProvider.overrideWith((ref) {
          controller = _RecordingAppStartupController(ref, signOutRelease);
          return controller;
        }),
      ],
    );
    addTearDown(() {
      if (!signOutRelease.isCompleted) signOutRelease.complete();
      container.dispose();
    });

    container.read(appStartupProvider);
    container.read(unauthorizedSignalProvider.notifier).state++;
    container.read(unauthorizedSignalProvider.notifier).state++;

    await Future<void>.delayed(Duration.zero);

    expect(controller.signOutCalls, 1);
    expect(controller.unauthorizedArguments, [true]);

    signOutRelease.complete();
    await controller.lastSignOutCall;

    container.read(unauthorizedSignalProvider.notifier).state++;
    await _waitForSignOutCalls(controller, 2);

    expect(controller.unauthorizedArguments, [true, true]);
  });

  test('unauthorized signal after local sign-out is ignored', () async {
    final signOutRelease = Completer<void>();
    late _RecordingAppStartupController controller;
    final container = ProviderContainer(
      overrides: [
        appStartupProvider.overrideWith((ref) {
          controller = _RecordingAppStartupController(ref, signOutRelease);
          return controller;
        }),
      ],
    );
    addTearDown(() {
      if (!signOutRelease.isCompleted) signOutRelease.complete();
      container.dispose();
    });

    container.read(appStartupProvider);
    expect(container.read(authProvider).session, isNull);

    container.read(unauthorizedSignalProvider.notifier).state++;
    await Future<void>.delayed(Duration.zero);

    expect(controller.signOutCalls, 0);
  });
}

AuthNotifier _authenticatedAuthNotifier(Ref ref) {
  return _AuthenticatedAuthNotifier(ref);
}

class _AuthenticatedAuthNotifier extends AuthNotifier {
  _AuthenticatedAuthNotifier(Ref ref)
    : super(ref, AuthApiService(Dio()), AuthSecureStorage()) {
    state = const AuthState(
      session: AuthSession(sessionToken: 'session-token'),
    );
  }
}

Future<void> _waitForSignOutCalls(
  _RecordingAppStartupController controller,
  int count,
) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    if (controller.signOutCalls >= count) return;
    await Future<void>.delayed(Duration.zero);
  }
  expect(controller.signOutCalls, count);
}

class _RecordingAppStartupController extends AppStartupController {
  final Completer<void> signOutRelease;
  final List<bool> unauthorizedArguments = [];
  int signOutCalls = 0;
  Future<void>? lastSignOutCall;

  _RecordingAppStartupController(Ref ref, this.signOutRelease)
    : super(ref, AppModeStorage());

  @override
  Future<void> forceSignedOut({bool unauthorized = false}) {
    signOutCalls++;
    unauthorizedArguments.add(unauthorized);
    return lastSignOutCall = signOutRelease.future;
  }
}
