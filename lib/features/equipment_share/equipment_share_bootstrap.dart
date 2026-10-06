import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/router/app_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:prokat/features/equipment_share/equipment_share_install_referrer.dart';
import 'package:prokat/features/equipment_share/equipment_share_link.dart';
import 'package:prokat/features/equipment_share/equipment_share_overlay.dart';
import 'package:prokat/features/equipment_share/equipment_share_storage.dart';

final equipmentShareBootstrapProvider = Provider<void>((ref) {
  final storage = ref.watch(equipmentShareStorageProvider);
  final router = ref.watch(routerProvider);
  final appLinks = AppLinks();
  StreamSubscription<Uri>? subscription;
  String? lastCanonical;
  DateTime? lastAt;
  var initialHandled = false;
  var consumeInFlight = false;
  var consumeAgain = false;

  Future<void> writeOverlay({
    required String equipmentId,
    required bool afterAuth,
  }) async {
    await storage.saveOverlay(
      EquipmentShareOverlay(
        path: AppRoutes.equipmentSharePath(equipmentId),
        afterAuth: afterAuth,
      ),
    );
  }

  Future<void> consumeOnce() async {
    final snapshot = await storage.readOverlaySnapshot();
    final decision = decideShareOverlay(
      overlay: snapshot.overlay,
      routeState: ref.read(appStartupProvider).routeState,
      currentPath: router.state.uri.path,
    );

    switch (decision.action) {
      case ShareOverlayAction.wait:
        return;
      case ShareOverlayAction.clear:
        await storage.clearOverlayIfUnchanged(snapshot.token);
        return;
      case ShareOverlayAction.push:
        // Push only the overlay this pass actually removed. If a newer one
        // was written meanwhile, it stays for the next pass.
        final claimed = await storage.clearOverlayIfUnchanged(snapshot.token);
        final path = decision.path;
        if (!claimed || path == null || path.isEmpty) return;
        unawaited(router.push(path));
    }
  }

  // A request during an in-flight consume runs one more pass instead of being
  // dropped, so an overlay written meanwhile is still opened. The flag is
  // checked again after unlocking: a request in the finally-gap would
  // otherwise be lost.
  Future<void> consumeOverlayIfAny() async {
    if (consumeInFlight) {
      consumeAgain = true;
      return;
    }
    consumeInFlight = true;
    try {
      do {
        consumeAgain = false;
        await consumeOnce();
      } while (consumeAgain);
    } finally {
      consumeInFlight = false;
    }
    if (consumeAgain) {
      unawaited(consumeOverlayIfAny());
    }
  }

  Future<void> openOrStore(Uri uri) async {
    final link = EquipmentShareLink.tryParse(uri);
    if (link == null) return;

    final canonical = link.canonical.toString();
    final now = DateTime.now();
    if (lastCanonical == canonical &&
        lastAt != null &&
        now.difference(lastAt!) < const Duration(seconds: 2)) {
      return;
    }
    lastCanonical = canonical;
    lastAt = now;

    if (!shareStartupReady(ref.read(appStartupProvider).routeState)) {
      await storage.savePendingUri(canonical);
      return;
    }

    await writeOverlay(equipmentId: link.equipmentId, afterAuth: false);
    await storage.clearPendingUri();
    await consumeOverlayIfAny();
  }

  Future<void> flushPendingUriIfAny() async {
    final pending = await storage.readPendingUri();
    if (pending == null) {
      await consumeOverlayIfAny();
      return;
    }

    final link = EquipmentShareLink.tryParse(Uri.parse(pending));
    if (link == null) {
      await storage.clearPendingUri();
      await consumeOverlayIfAny();
      return;
    }

    if (!shareStartupReady(ref.read(appStartupProvider).routeState)) {
      await storage.savePendingUri(link.canonical.toString());
      return;
    }

    await writeOverlay(equipmentId: link.equipmentId, afterAuth: false);
    await storage.clearPendingUri();
    await consumeOverlayIfAny();
  }

  Future<void> start() async {
    if (!initialHandled) {
      initialHandled = true;
      try {
        final initial = await appLinks.getInitialLink();
        if (initial != null) {
          await openOrStore(initial);
          await storage.markInstallReferrerChecked();
        } else {
          final link = await captureShareInstallReferrer(
            wasChecked: storage.wasInstallReferrerChecked,
            markChecked: storage.markInstallReferrerChecked,
            readReferrer: readPlayInstallReferrer,
          );
          if (link != null) await openOrStore(link.canonical);
        }
      } catch (_) {}
    }

    subscription ??= appLinks.uriLinkStream.listen((uri) {
      unawaited(openOrStore(uri));
    });
  }

  void onRouterChanged() {
    unawaited(consumeOverlayIfAny());
  }

  router.routerDelegate.addListener(onRouterChanged);

  ref.listen(appStartupProvider, (previous, next) {
    unawaited(flushPendingUriIfAny());
  });

  ref.onDispose(() {
    unawaited(subscription?.cancel());
    router.routerDelegate.removeListener(onRouterChanged);
  });

  unawaited(start());
  unawaited(flushPendingUriIfAny());
});
