import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:prokat/features/auth/models/auth_session.dart';
import 'package:prokat/features/auth/providers/auth_api_service.dart';
import 'package:prokat/features/auth/providers/auth_notifier.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/auth/providers/auth_secure_storage.dart';
import 'package:prokat/features/auth/providers/auth_state.dart';
import 'package:prokat/features/auth/screens/login_screen.dart';
import 'package:prokat/features/auth/widgets/logout_button.dart';
import 'package:prokat/l10n/app_localizations.dart';

void main() {
  testWidgets('confirmed logout opens the guest catalog immediately', (
    tester,
  ) async {
    final signOutRelease = Completer<void>();
    late _ControlledAppStartupController startupController;
    final router = GoRouter(
      initialLocation: '/protected',
      routes: [
        GoRoute(
          path: '/protected',
          builder: (_, _) => const Scaffold(body: LogoutButton()),
        ),
        GoRoute(
          path: '/login',
          builder: (_, _) => const Scaffold(body: Text('Login')),
        ),
        GoRoute(
          path: '/main',
          builder: (_, _) => const Scaffold(body: Text('Guest catalog')),
        ),
      ],
    );
    addTearDown(() {
      if (!signOutRelease.isCompleted) signOutRelease.complete();
      router.dispose();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(_authenticatedAuthNotifier),
          appStartupProvider.overrideWith((ref) {
            startupController = _ControlledAppStartupController(
              ref,
              signOutRelease.future,
            );
            return startupController;
          }),
        ],
        child: _LocalizedRouterApp(router: router),
      ),
    );

    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Logout'));
    await tester.pump();
    await tester.pump();

    expect(startupController.signOutCalls, 1);
    expect(find.text('Guest catalog'), findsOneWidget);
    expect(find.text('Login'), findsNothing);

    signOutRelease.complete();
    await tester.pumpAndSettle();
    expect(find.text('Guest catalog'), findsOneWidget);
  });

  testWidgets('login Back returns a guest to the catalog', (tester) async {
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
        GoRoute(
          path: '/main',
          builder: (_, _) => const Scaffold(body: Text('Guest catalog')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authProvider.overrideWith(_anonymousAuthNotifier)],
        child: _LocalizedRouterApp(router: router),
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Guest catalog'), findsOneWidget);
  });
}

class _LocalizedRouterApp extends StatelessWidget {
  final GoRouter router;

  const _LocalizedRouterApp({required this.router});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}

AuthNotifier _authenticatedAuthNotifier(Ref ref) {
  return _TestAuthNotifier(
    ref,
    const AuthState(session: AuthSession(sessionToken: 'session-token')),
  );
}

AuthNotifier _anonymousAuthNotifier(Ref ref) {
  return _TestAuthNotifier(ref, const AuthState());
}

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier(Ref ref, AuthState initialState)
    : super(ref, AuthApiService(Dio()), AuthSecureStorage()) {
    state = initialState;
  }
}

class _ControlledAppStartupController extends AppStartupController {
  final Future<void> signOutResult;
  int signOutCalls = 0;

  _ControlledAppStartupController(Ref ref, this.signOutResult)
    : super(ref, AppModeStorage());

  @override
  Future<void> forceSignedOut({bool unauthorized = false}) {
    signOutCalls++;
    return signOutResult;
  }
}
