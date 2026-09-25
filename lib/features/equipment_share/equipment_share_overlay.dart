import 'dart:convert';

import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:prokat/features/equipment_share/equipment_share_link.dart';

/// One-shot instruction to push `/e/<id>` after the stack is ready.
class EquipmentShareOverlay {
  final String path;
  final bool afterAuth;

  const EquipmentShareOverlay({required this.path, required this.afterAuth});

  String get equipmentId => sharePathEquipmentId(path) ?? '';

  Map<String, dynamic> toJson() => {'path': path, 'afterAuth': afterAuth};

  static EquipmentShareOverlay? tryParse(String raw) {
    try {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return null;

      if (trimmed.startsWith('{')) {
        final decoded = jsonDecode(trimmed);
        if (decoded is! Map) return null;
        final map = Map<String, dynamic>.from(decoded);
        final path = map['path']?.toString().trim() ?? '';
        if (sharePathEquipmentId(path) == null) return null;
        return EquipmentShareOverlay(
          path: path,
          afterAuth: map['afterAuth'] == true,
        );
      }

      final link = EquipmentShareLink.tryParse(Uri.parse(trimmed));
      if (link != null) {
        return EquipmentShareOverlay(
          path: AppRoutes.equipmentSharePath(link.equipmentId),
          afterAuth: false,
        );
      }

      if (sharePathEquipmentId(trimmed) != null) {
        return EquipmentShareOverlay(path: trimmed, afterAuth: false);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

enum ShareOverlayAction { wait, clear, push }

class ShareOverlayDecision {
  final ShareOverlayAction action;
  final String? path;

  const ShareOverlayDecision.wait()
    : action = ShareOverlayAction.wait,
      path = null;

  const ShareOverlayDecision.clear()
    : action = ShareOverlayAction.clear,
      path = null;

  const ShareOverlayDecision.push(this.path) : action = ShareOverlayAction.push;
}

bool shareStartupReady(AppStartupRouteState state) {
  return state == AppStartupRouteState.guest ||
      state == AppStartupRouteState.client ||
      state == AppStartupRouteState.owner;
}

String? sharePathEquipmentId(String path) {
  final segments = Uri.tryParse(path)?.pathSegments;
  if (segments == null || segments.length < 2 || segments[0] != 'e') {
    return null;
  }
  // `/e/:id` or `/e/:id/address`
  final id = segments[1];
  if (id.isEmpty || id == '.' || id == '..') return null;
  if (segments.length > 2 && segments[2] != 'address') return null;
  if (segments.length > 3) return null;
  return id;
}

bool isEquipmentShareTop(String currentPath) {
  return sharePathEquipmentId(currentPath) != null;
}

ShareOverlayDecision decideShareOverlay({
  required EquipmentShareOverlay? overlay,
  required AppStartupRouteState routeState,
  required String currentPath,
}) {
  if (overlay == null) return const ShareOverlayDecision.clear();

  final targetId = sharePathEquipmentId(overlay.path);
  if (targetId == null) return const ShareOverlayDecision.clear();

  if (!shareStartupReady(routeState)) {
    return const ShareOverlayDecision.wait();
  }

  if (currentPath == AppRoutes.launch ||
      currentPath == AppRoutes.login ||
      currentPath == AppRoutes.error) {
    return const ShareOverlayDecision.wait();
  }

  final topId = sharePathEquipmentId(currentPath);
  if (topId != null && topId == targetId) {
    return const ShareOverlayDecision.clear();
  }

  if (overlay.afterAuth) {
    if (routeState == AppStartupRouteState.guest) {
      if (currentPath == AppRoutes.main) {
        return const ShareOverlayDecision.clear();
      }
      return const ShareOverlayDecision.wait();
    }

    // client / owner after auth: push once landing (or any stable app path) is
    // under the stack. Redirect already returned the canonical landing.
    return ShareOverlayDecision.push(overlay.path);
  }

  return ShareOverlayDecision.push(overlay.path);
}
