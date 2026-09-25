import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/router/post_login_location.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:prokat/features/equipment_share/equipment_share_overlay.dart';

void main() {
  testWidgets('landing push Back stays on landing', (tester) async {
    final router = _shareRouter(initialLocation: AppRoutes.main);
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    expect(find.text('Landing'), findsOneWidget);

    router.push('/e/eq-1');
    await tester.pumpAndSettle();
    expect(find.text('Share eq-1'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('Landing'), findsOneWidget);
    expect(find.text('Share eq-1'), findsNothing);
  });

  testWidgets('in-app push Back returns to the previous shell screen', (
    tester,
  ) async {
    final router = _shareRouter(initialLocation: '/client/orders');
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    expect(find.text('Orders'), findsOneWidget);

    router.push('/e/eq-1');
    await tester.pumpAndSettle();
    expect(find.text('Share eq-1'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('Orders'), findsOneWidget);
    expect(find.text('Landing'), findsNothing);
  });

  testWidgets('address nested Back pops to card then underlying', (
    tester,
  ) async {
    final router = _shareRouter(initialLocation: '/client/orders');
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.push('/e/eq-1');
    await tester.pumpAndSettle();
    router.push('/e/eq-1/address');
    await tester.pumpAndSettle();
    expect(find.text('Address eq-1'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('Share eq-1'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('Orders'), findsOneWidget);
  });

  testWidgets('PopScope didPop true does not go landing again', (tester) async {
    var fallbackCalls = 0;
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: Text('Home')),
        ),
        GoRoute(
          path: '/card',
          builder: (context, _) {
            return PopScope(
              canPop: true,
              onPopInvokedWithResult: (didPop, _) {
                if (didPop) return;
                fallbackCalls += 1;
              },
              child: Scaffold(
                appBar: AppBar(
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => GoRouter.of(context).pop(),
                  ),
                ),
                body: const Text('Card'),
              ),
            );
          },
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.push('/card');
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(fallbackCalls, 0);
  });

  testWidgets('post-login landing plus one share push', (tester) async {
    final signedIn = ValueNotifier(false);
    addTearDown(signedIn.dispose);
    var pushCount = 0;
    EquipmentShareOverlay? pending = const EquipmentShareOverlay(
      path: '/e/eq-1',
      afterAuth: true,
    );

    final router = GoRouter(
      initialLocation: AppRoutes.login,
      refreshListenable: signedIn,
      redirect: (_, state) {
        if (!signedIn.value) return null;
        if (state.matchedLocation == AppRoutes.login) {
          final dest = resolvePostLoginLocation(
            from: '/e/eq-1',
            ownerModeActive: false,
            accountIsOwner: false,
          );
          if (dest.startsWith('/e/')) {
            return startupLandingLocation(AppStartupRouteState.client);
          }
          return dest;
        }
        return null;
      },
      routes: [
        GoRoute(
          path: AppRoutes.login,
          builder: (_, _) => const Scaffold(body: Text('Login')),
        ),
        GoRoute(
          path: AppRoutes.searchList,
          builder: (_, _) => const Scaffold(body: Text('Search')),
        ),
        GoRoute(
          path: '/e/:id',
          builder: (_, state) =>
              Scaffold(body: Text('Share ${state.pathParameters['id']}')),
        ),
      ],
    );
    addTearDown(router.dispose);

    Future<void> consume() async {
      final decision = decideShareOverlay(
        overlay: pending,
        routeState: signedIn.value
            ? AppStartupRouteState.client
            : AppStartupRouteState.guest,
        currentPath: router.state.uri.path,
      );
      if (decision.action == ShareOverlayAction.wait) return;
      if (decision.action == ShareOverlayAction.clear) {
        pending = null;
        return;
      }
      pending = null;
      pushCount += 1;
      router.push(decision.path!);
    }

    router.routerDelegate.addListener(() {
      // ignore: discarded_futures
      consume();
    });

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    expect(find.text('Login'), findsOneWidget);

    signedIn.value = true;
    await tester.pumpAndSettle();
    await consume();
    await tester.pumpAndSettle();
    // Simulate another startup refresh notification.
    await consume();
    await tester.pumpAndSettle();

    expect(find.text('Share eq-1'), findsOneWidget);
    expect(find.text('Search'), findsNothing);
    expect(pushCount, 1);
    expect(router.canPop(), isTrue);
  });
}

GoRouter _shareRouter({required String initialLocation}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      StatefulShellRoute.indexedStack(
        pageBuilder: (_, state, navigationShell) => NoTransitionPage<void>(
          key: state.pageKey,
          child: Scaffold(body: navigationShell),
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.main,
                builder: (_, _) => const Scaffold(body: Text('Landing')),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/client/orders',
                builder: (_, _) => const Scaffold(body: Text('Orders')),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/e/:id',
        builder: (_, state) =>
            Scaffold(body: Text('Share ${state.pathParameters['id']}')),
        routes: [
          GoRoute(
            path: 'address',
            builder: (_, state) =>
                Scaffold(body: Text('Address ${state.pathParameters['id']}')),
          ),
        ],
      ),
    ],
  );
}
