import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/router/app_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:prokat/features/equipment_share/equipment_share_link.dart';
import 'package:prokat/features/equipment_share/equipment_share_storage.dart';

final equipmentShareBootstrapProvider = Provider<void>((ref) {
  final storage = ref.watch(equipmentShareStorageProvider);
  final router = ref.watch(routerProvider);
  final appLinks = AppLinks();
  StreamSubscription<Uri>? subscription;
  String? lastCanonical;
  DateTime? lastAt;
  var initialHandled = false;

  bool ready(AppStartupRouteState state) {
    return state == AppStartupRouteState.guest ||
        state == AppStartupRouteState.client ||
        state == AppStartupRouteState.owner;
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

    if (!ready(ref.read(appStartupProvider).routeState)) {
      await storage.savePendingUri(canonical);
      return;
    }

    router.go(AppRoutes.equipmentSharePath(link.equipmentId));
  }

  Future<void> flushPendingUriIfAny() async {
    final pending = await storage.readPendingUri();
    if (pending == null) return;

    final link = EquipmentShareLink.tryParse(Uri.parse(pending));
    if (link == null) {
      await storage.clearPendingUri();
      return;
    }

    if (!ready(ref.read(appStartupProvider).routeState)) {
      await storage.savePendingUri(link.canonical.toString());
      return;
    }

    await storage.clearPendingUri();
    router.go(AppRoutes.equipmentSharePath(link.equipmentId));
  }

  Future<void> start() async {
    if (!initialHandled) {
      initialHandled = true;
      try {
        final initial = await appLinks.getInitialLink();
        if (initial != null) await openOrStore(initial);
      } catch (_) {}
    }

    subscription ??= appLinks.uriLinkStream.listen((uri) {
      unawaited(openOrStore(uri));
    });
  }

  ref.listen(appStartupProvider, (previous, next) {
    unawaited(flushPendingUriIfAny());
  });

  ref.onDispose(() {
    unawaited(subscription?.cancel());
  });

  unawaited(start());
  unawaited(flushPendingUriIfAny());
});
