import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/analytics/analytics_service.dart';
import 'package:prokat/core/analytics/screen_tracking.dart';
import 'package:prokat/core/router/app_router.dart';
import 'package:prokat/core/router/app_routes.dart';

import '../../helpers/recording_analytics_client.dart';

const _equipmentId = '3f2b8c1e-9d4a-4e7b-a6c5-1b2d3e4f5a6b';

Widget _page(GoRouterState state) => Scaffold(body: Text(state.uri.path));

GoRoute _leaf(String path) =>
    GoRoute(path: path, builder: (_, state) => _page(state));

StatefulNavigationShell? _shell;

GoRouter _buildRouter(String initialLocation) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    _leaf(AppRoutes.launch),
    StatefulShellRoute.indexedStack(
      pageBuilder: (_, state, navigationShell) {
        _shell = navigationShell;
        return NoTransitionPage<void>(
          key: state.pageKey,
          child: navigationShell,
        );
      },
      branches: [
        StatefulShellBranch(routes: [_leaf(AppRoutes.main)]),
        StatefulShellBranch(
          routes: [
            _leaf(AppRoutes.searchList),
            _leaf(AppRoutes.clientProfile),
            _leaf(AppRoutes.becomeOwner),
          ],
        ),
        StatefulShellBranch(
          routes: [
            _leaf(AppRoutes.ownerProfile),
            _leaf(AppRoutes.ownerRegistration),
            GoRoute(
              path: AppRoutes.ownerEquipment,
              builder: (_, state) => _page(state),
              routes: [_leaf(AppRoutes.create), _leaf(AppRoutes.id)],
            ),
            _leaf(AppRoutes.ownerPayment),
          ],
        ),
      ],
    ),
  ],
);

Future<(GoRouter, RecordingAnalyticsClient)> _pumpTracked(
  WidgetTester tester,
  String initialLocation,
) async {
  final client = RecordingAnalyticsClient();
  final router = _buildRouter(initialLocation);
  addTearDown(router.dispose);
  final container = ProviderContainer(
    overrides: [
      routerProvider.overrideWithValue(router),
      analyticsServiceProvider.overrideWithValue(AnalyticsService(client)),
    ],
  );
  addTearDown(container.dispose);
  container.read(screenTrackingBootstrapProvider);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return (router, client);
}

void main() {
  group('analyticsScreenNameFor', () {
    test('maps all nine route templates', () {
      expect(analyticsScreenNameFor(AppRoutes.main), 'guest_main');
      expect(analyticsScreenNameFor(AppRoutes.searchList), 'client_search');
      expect(analyticsScreenNameFor(AppRoutes.clientProfile), 'client_profile');
      expect(analyticsScreenNameFor(AppRoutes.becomeOwner), 'become_owner');
      expect(analyticsScreenNameFor(AppRoutes.ownerProfile), 'owner_profile');
      expect(
        analyticsScreenNameFor(AppRoutes.ownerRegistration),
        'owner_business_profile',
      );
      expect(
        analyticsScreenNameFor(AppRoutes.ownerEquipment),
        'owner_equipment_list',
      );
      expect(
        analyticsScreenNameFor(AppRoutes.ownerEquipmentCreate),
        'owner_equipment_create',
      );
      expect(
        analyticsScreenNameFor(AppRoutes.ownerEquipmentId),
        'owner_equipment_detail',
      );
      expect(analyticsScreenNames, hasLength(9));
    });

    test('returns null for non-allowlisted routes', () {
      expect(analyticsScreenNameFor(AppRoutes.launch), isNull);
      expect(analyticsScreenNameFor(AppRoutes.login), isNull);
      expect(analyticsScreenNameFor(AppRoutes.ownerPayment), isNull);
      expect(analyticsScreenNameFor(AppRoutes.equipmentShare), isNull);
      expect(
        analyticsScreenNameFor('${AppRoutes.ownerEquipment}/$_equipmentId'),
        isNull,
      );
    });

    test('null returns null', () {
      expect(analyticsScreenNameFor(null), isNull);
    });
  });

  test('repeated route notification does not duplicate screen_view', () async {
    final client = RecordingAnalyticsClient();
    final tracker = ScreenTracker(AnalyticsService(client));

    tracker.onRoute(AppRoutes.ownerEquipment);
    tracker.onRoute(AppRoutes.ownerEquipment);
    tracker.onRoute(AppRoutes.ownerEquipment);
    await Future<void>.value();

    expect(client.screens, ['owner_equipment_list']);
  });

  group('router integration', () {
    testWidgets('initial route is tracked by the delegate listener', (
      tester,
    ) async {
      final (router, client) = await _pumpTracked(
        tester,
        AppRoutes.ownerEquipment,
      );

      expect(router.state.fullPath, AppRoutes.ownerEquipment);
      expect(client.screens, ['owner_equipment_list']);
    });

    testWidgets('push equipment create logs owner_equipment_create', (
      tester,
    ) async {
      final (router, client) = await _pumpTracked(
        tester,
        AppRoutes.ownerEquipment,
      );

      unawaited(router.push(AppRoutes.ownerEquipmentCreate));
      await tester.pumpAndSettle();

      expect(router.state.fullPath, AppRoutes.ownerEquipmentCreate);
      expect(client.screens, [
        'owner_equipment_list',
        'owner_equipment_create',
      ]);
    });

    testWidgets('equipment detail logs the template, never the uuid', (
      tester,
    ) async {
      final (router, client) = await _pumpTracked(
        tester,
        AppRoutes.ownerEquipment,
      );

      unawaited(router.push('${AppRoutes.ownerEquipment}/$_equipmentId'));
      await tester.pumpAndSettle();

      expect(router.state.fullPath, AppRoutes.ownerEquipmentId);
      expect(router.state.uri.path, '/owner/equipment/$_equipmentId');
      expect(client.screens, [
        'owner_equipment_list',
        'owner_equipment_detail',
      ]);

      router.go(AppRoutes.ownerProfile);
      await tester.pumpAndSettle();
      router.go('${AppRoutes.ownerEquipment}/$_equipmentId');
      await tester.pumpAndSettle();

      expect(router.state.fullPath, AppRoutes.ownerEquipmentId);
      expect(client.screens.last, 'owner_equipment_detail');
      for (final name in client.screens) {
        expect(name, isNot(contains(_equipmentId)));
        expect(name, isNot(contains('/')));
      }
    });

    testWidgets('re-navigating to the same route does not duplicate', (
      tester,
    ) async {
      final (router, client) = await _pumpTracked(
        tester,
        AppRoutes.ownerEquipment,
      );

      router.go(AppRoutes.ownerEquipment);
      await tester.pumpAndSettle();
      router.refresh();
      await tester.pumpAndSettle();

      expect(client.screens, ['owner_equipment_list']);
    });

    testWidgets('list -> detail -> list logs list again on return', (
      tester,
    ) async {
      final (router, client) = await _pumpTracked(
        tester,
        AppRoutes.ownerEquipment,
      );

      unawaited(router.push('${AppRoutes.ownerEquipment}/$_equipmentId'));
      await tester.pumpAndSettle();
      router.pop();
      await tester.pumpAndSettle();

      expect(router.state.fullPath, AppRoutes.ownerEquipment);
      expect(client.screens, [
        'owner_equipment_list',
        'owner_equipment_detail',
        'owner_equipment_list',
      ]);
    });

    testWidgets('non-allowlisted route resets dedup', (tester) async {
      final (router, client) = await _pumpTracked(
        tester,
        AppRoutes.ownerProfile,
      );

      router.go(AppRoutes.ownerPayment);
      await tester.pumpAndSettle();
      router.go(AppRoutes.ownerProfile);
      await tester.pumpAndSettle();

      expect(client.screens, ['owner_profile', 'owner_profile']);
    });

    testWidgets('unmatched location resets dedup without throwing', (
      tester,
    ) async {
      final (router, client) = await _pumpTracked(
        tester,
        AppRoutes.ownerProfile,
      );

      router.go('/does-not-exist');
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.isEmpty, isTrue);
      router.go(AppRoutes.ownerProfile);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(client.screens, ['owner_profile', 'owner_profile']);
    });

    testWidgets('switching shell branch logs the target branch screen', (
      tester,
    ) async {
      final (router, client) = await _pumpTracked(
        tester,
        AppRoutes.ownerEquipment,
      );

      router.go(AppRoutes.searchList);
      await tester.pumpAndSettle();
      _shell!.goBranch(2);
      await tester.pumpAndSettle();

      expect(router.state.fullPath, AppRoutes.ownerEquipment);
      expect(client.screens, [
        'owner_equipment_list',
        'client_search',
        'owner_equipment_list',
      ]);
    });
  });
}
