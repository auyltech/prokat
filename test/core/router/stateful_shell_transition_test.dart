import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('guest login replaces the shell before authenticated redirect', (
    tester,
  ) async {
    final signedIn = ValueNotifier(false);
    addTearDown(signedIn.dispose);

    final router = GoRouter(
      initialLocation: '/home',
      refreshListenable: signedIn,
      redirect: (_, state) {
        if (signedIn.value && state.matchedLocation == '/login') {
          return '/home';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (_, _) => const Scaffold(body: Text('Login')),
        ),
        StatefulShellRoute.indexedStack(
          pageBuilder: (_, state, navigationShell) => NoTransitionPage<void>(
            key: state.pageKey,
            child: Scaffold(body: navigationShell),
          ),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (context, _) => TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Open login'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    expect(find.text('Open login'), findsOneWidget);

    await tester.tap(find.text('Open login'));
    await tester.pumpAndSettle();
    expect(find.text('Login'), findsOneWidget);

    signedIn.value = true;
    await tester.pumpAndSettle();

    expect(find.text('Open login'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
