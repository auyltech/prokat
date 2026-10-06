import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/router/app_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:prokat/features/equipment_share/equipment_share_install_referrer.dart';
import 'package:prokat/features/equipment_share/equipment_share_link.dart';
import 'package:prokat/features/equipment_share/equipment_share_open.dart';
import 'package:prokat/features/equipment_share/equipment_share_open_recorder.dart';
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
  var flushChain = Future<void>.value();

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

  Future<void> consumeOverlayIfAny() async {
    if (consumeInFlight) return;
    consumeInFlight = true;
    try {
      final overlay = await storage.readOverlay();
      final decision = decideShareOverlay(
        overlay: overlay,
        routeState: ref.read(appStartupProvider).routeState,
        currentPath: router.state.uri.path,
      );

      switch (decision.action) {
        case ShareOverlayAction.wait:
          return;
        case ShareOverlayAction.clear:
          await storage.clearOverlay();
          return;
        case ShareOverlayAction.push:
          final path = decision.path;
          if (path == null || path.isEmpty) {
            await storage.clearOverlay();
            return;
          }
          await storage.clearOverlay();
          unawaited(router.push(path));
      }
    } finally {
      consumeInFlight = false;
    }
  }

  Future<void> openOrStore(
    Uri uri, {
    required ShareOpenVia via,
    required bool firstShareBootstrapRun,
  }) async {
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

    final open = EquipmentShareOpen(
      link: link,
      via: via,
      firstShareBootstrapRun: firstShareBootstrapRun,
    );
    if (!shareStartupReady(ref.read(appStartupProvider).routeState)) {
      await storage.savePendingOpen(open);
      return;
    }

    unawaited(ref.read(shareOpenRecorderProvider).record(open));
    await writeOverlay(equipmentId: link.equipmentId, afterAuth: false);
    await storage.clearPendingUri();
    await consumeOverlayIfAny();
  }

  Future<void> flushPendingOnce() async {
    final open = await storage.readPendingOpen();
    if (open == null) {
      await consumeOverlayIfAny();
      return;
    }

    if (!shareStartupReady(ref.read(appStartupProvider).routeState)) {
      await storage.savePendingOpen(open);
      return;
    }

    unawaited(ref.read(shareOpenRecorderProvider).record(open));
    await writeOverlay(equipmentId: open.link.equipmentId, afterAuth: false);
    await storage.clearPendingUri();
    await consumeOverlayIfAny();
  }

  // Serialized: overlapping startup notifications must not both read the same
  // pending open and record it twice. A failed run must not stall the chain.
  Future<void> flushPendingUriIfAny() {
    final run = flushChain.then((_) => flushPendingOnce());
    flushChain = run.then((_) {}, onError: (Object _) {});
    return run;
  }

  Future<void> start() async {
    if (!initialHandled) {
      initialHandled = true;
      try {
        final firstShareBootstrapRun = !(await storage
            .wasInstallReferrerChecked());
        final initial = await appLinks.getInitialLink();
        if (initial != null) {
          await openOrStore(
            initial,
            via: ShareOpenVia.appLink,
            firstShareBootstrapRun: firstShareBootstrapRun,
          );
          await storage.markInstallReferrerChecked();
        } else {
          final link = await captureShareInstallReferrer(
            wasChecked: storage.wasInstallReferrerChecked,
            markChecked: storage.markInstallReferrerChecked,
            readReferrer: readPlayInstallReferrer,
          );
          if (link != null) {
            await openOrStore(
              link.uri,
              via: ShareOpenVia.installReferrer,
              firstShareBootstrapRun: firstShareBootstrapRun,
            );
          }
        }
      } catch (_) {}
    }

    subscription ??= appLinks.uriLinkStream.listen((uri) {
      unawaited(
        openOrStore(
          uri,
          via: ShareOpenVia.appLink,
          firstShareBootstrapRun: false,
        ),
      );
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
