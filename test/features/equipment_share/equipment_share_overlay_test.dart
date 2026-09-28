import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:prokat/features/equipment_share/equipment_share_overlay.dart';

void main() {
  EquipmentShareOverlay overlay({
    String path = '/e/eq-1',
    bool afterAuth = false,
  }) {
    return EquipmentShareOverlay(path: path, afterAuth: afterAuth);
  }

  group('decideShareOverlay', () {
    test('waits while startup is not ready', () {
      expect(
        decideShareOverlay(
          overlay: overlay(),
          routeState: AppStartupRouteState.loading,
          currentPath: AppRoutes.main,
        ).action,
        ShareOverlayAction.wait,
      );
    });

    test('waits on launch login and error', () {
      for (final path in [AppRoutes.launch, AppRoutes.login, AppRoutes.error]) {
        expect(
          decideShareOverlay(
            overlay: overlay(),
            routeState: AppStartupRouteState.guest,
            currentPath: path,
          ).action,
          ShareOverlayAction.wait,
          reason: path,
        );
      }
    });

    test('clears when the same card is already on top', () {
      expect(
        decideShareOverlay(
          overlay: overlay(),
          routeState: AppStartupRouteState.guest,
          currentPath: '/e/eq-1',
        ).action,
        ShareOverlayAction.clear,
      );
      expect(
        decideShareOverlay(
          overlay: overlay(),
          routeState: AppStartupRouteState.client,
          currentPath: '/e/eq-1/address',
        ).action,
        ShareOverlayAction.clear,
      );
    });

    test('pushes a different equipment on top of the current card', () {
      final decision = decideShareOverlay(
        overlay: overlay(path: '/e/eq-2'),
        routeState: AppStartupRouteState.client,
        currentPath: '/e/eq-1',
      );
      expect(decision.action, ShareOverlayAction.push);
      expect(decision.path, '/e/eq-2');
    });

    test('afterAuth waits while still guest except cancel on main', () {
      expect(
        decideShareOverlay(
          overlay: overlay(afterAuth: true),
          routeState: AppStartupRouteState.guest,
          currentPath: AppRoutes.login,
        ).action,
        ShareOverlayAction.wait,
      );
      expect(
        decideShareOverlay(
          overlay: overlay(afterAuth: true),
          routeState: AppStartupRouteState.guest,
          currentPath: AppRoutes.main,
        ).action,
        ShareOverlayAction.clear,
      );
    });

    test('afterAuth pushes once the account is client or owner', () {
      expect(
        decideShareOverlay(
          overlay: overlay(afterAuth: true),
          routeState: AppStartupRouteState.client,
          currentPath: AppRoutes.searchList,
        ).action,
        ShareOverlayAction.push,
      );
      expect(
        decideShareOverlay(
          overlay: overlay(afterAuth: true),
          routeState: AppStartupRouteState.owner,
          currentPath: AppRoutes.ownerEquipment,
        ).action,
        ShareOverlayAction.push,
      );
    });

    test('warm link pushes over the current shell screen', () {
      final decision = decideShareOverlay(
        overlay: overlay(),
        routeState: AppStartupRouteState.client,
        currentPath: AppRoutes.clientOrders,
      );
      expect(decision.action, ShareOverlayAction.push);
      expect(decision.path, '/e/eq-1');
    });

    test('null or corrupt overlay clears', () {
      expect(
        decideShareOverlay(
          overlay: null,
          routeState: AppStartupRouteState.guest,
          currentPath: AppRoutes.main,
        ).action,
        ShareOverlayAction.clear,
      );
    });
  });

  test('overlay json round-trip', () {
    final parsed = EquipmentShareOverlay.tryParse(
      '{"path":"/e/eq-9","afterAuth":true}',
    );
    expect(parsed, isNotNull);
    expect(parsed!.path, '/e/eq-9');
    expect(parsed.afterAuth, isTrue);
    expect(parsed.equipmentId, 'eq-9');
  });
}
