import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/router/app_router.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:prokat/features/equipment_share/equipment_share_install_referrer.dart';
import 'package:prokat/features/equipment_share/equipment_share_ingress.dart';
import 'package:prokat/features/equipment_share/equipment_share_open.dart';
import 'package:prokat/features/equipment_share/equipment_share_open_recorder.dart';
import 'package:prokat/features/equipment_share/equipment_share_overlay.dart';
import 'package:prokat/features/equipment_share/equipment_share_storage.dart';
import 'package:prokat/features/equipment_share/equipment_share_resolver.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/l10n/app_localizations.dart';

final equipmentShareBootstrapProvider = Provider<EquipmentShareIngress>((ref) {
  final storage = ref.watch(equipmentShareStorageProvider);
  final router = ref.watch(routerProvider);
  final appLinks = AppLinks();
  StreamSubscription<Uri>? subscription;
  late final EquipmentShareIngress ingress;
  var initialHandled = false;
  var consumeInFlight = false;
  var flushChain = Future<void>.value();
  var consumeAgain = false;

  Future<void> consumeOnce() async {
    final generation = ingress.generation;
    final snapshot = await storage.readOverlaySnapshot();
    if (ingress.hasPendingIntent || ingress.generation != generation) return;
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
        if (!claimed ||
            path == null ||
            path.isEmpty ||
            ingress.hasPendingIntent ||
            ingress.generation != generation) {
          return;
        }
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

  Future<void> flushPendingOnce() async {
    await ingress.flushPendingUriIfAny();
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
    subscription ??= appLinks.uriLinkStream.listen((uri) {
      unawaited(
        ingress.acceptUri(
          uri,
          via: ShareOpenVia.appLink,
          firstShareBootstrapRun: false,
        ),
      );
    });
    if (!initialHandled) {
      initialHandled = true;
      final generation = ingress.generation;
      try {
        final firstShareBootstrapRun = !(await storage
            .wasInstallReferrerChecked());
        final initial = await appLinks.getInitialLink();
        if (ingress.generation != generation) return;
        if (initial != null) {
          final accepted = await ingress.acceptUri(
            initial,
            via: ShareOpenVia.appLink,
            firstShareBootstrapRun: firstShareBootstrapRun,
          );
          if (accepted) await storage.markInstallReferrerChecked();
        } else {
          final link = await captureShareInstallReferrer(
            wasChecked: storage.wasInstallReferrerChecked,
            markChecked: storage.markInstallReferrerChecked,
            readReferrer: readPlayInstallReferrer,
          );
          if (link != null && ingress.generation == generation) {
            await ingress.acceptUri(
              link.uri,
              via: ShareOpenVia.installReferrer,
              firstShareBootstrapRun: firstShareBootstrapRun,
            );
          }
        }
      } catch (_) {}
    }
  }

  ingress = EquipmentShareIngress(
    storage: storage,
    resolve: (shareId) =>
        ref.read(equipmentShareResolverProvider).resolve(shareId),
    isReady: () => shareStartupReady(ref.read(appStartupProvider).routeState),
    onAccepted: (open) async {
      unawaited(ref.read(shareOpenRecorderProvider).record(open));
      await consumeOverlayIfAny();
    },
    onFailure: (status) {
      final context = router.routerDelegate.navigatorKey.currentContext;
      final l10n = context == null ? null : AppLocalizations.of(context);
      if (l10n == null) return;
      AppToast.show(
        message:
            status == ShareResolutionStatus.unavailable ||
                status == ShareResolutionStatus.invalid
            ? l10n.shareEquipmentUnavailable
            : l10n.somethingWentWrongTryAgain,
        type: AppToastType.error,
      );
    },
  );

  void onRouterChanged() {
    unawaited(consumeOverlayIfAny());
  }

  router.routerDelegate.addListener(onRouterChanged);

  ref.listen(appStartupProvider, (previous, next) {
    unawaited(flushPendingUriIfAny());
  });

  ref.onDispose(() {
    ingress.dispose();
    unawaited(subscription?.cancel());
    router.routerDelegate.removeListener(onRouterChanged);
  });

  unawaited(start());
  unawaited(flushPendingUriIfAny());
  return ingress;
});
