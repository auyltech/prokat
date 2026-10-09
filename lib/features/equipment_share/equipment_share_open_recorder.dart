import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/analytics/analytics_service.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/equipment_share/equipment_share_events_api.dart';
import 'package:prokat/features/equipment_share/equipment_share_first_touch.dart';
import 'package:prokat/features/equipment_share/equipment_share_open.dart';

/// Records one accepted share open. The three side effects start together and
/// are isolated: a failure or delay in one never blocks or skips another.
class ShareOpenRecorder {
  ShareOpenRecorder({
    required this.analytics,
    required this.api,
    required this.isAuthenticated,
    required this.firstTouch,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  final AnalyticsService analytics;
  final EquipmentShareEventsApi api;
  final bool Function() isAuthenticated;
  final EquipmentShareFirstTouchStore firstTouch;
  final DateTime Function() now;

  Future<void> record(EquipmentShareOpen open) async {
    final link = open.link;
    final equipmentId = link.equipmentId;
    final openVia = open.via.api;
    if (equipmentId == null || openVia == null) return;
    await Future.wait([
      _guard(
        () => analytics.logShareLinkOpened(
          equipmentId: link.isRegistryLink ? null : equipmentId,
          shareId: link.shareId,
          via: open.via,
          firstShareBootstrapRun: open.firstShareBootstrapRun,
        ),
      ),
      _guard(
        () => api.recordOpened(
          equipmentId: equipmentId,
          shareId: link.shareId,
          openVia: openVia,
          firstShareBootstrapRun: open.firstShareBootstrapRun,
        ),
      ),
      _guard(() async {
        if (!isAuthenticated()) {
          await firstTouch.saveIfEmpty(
            FirstTouchAttribution(
              shareId: link.shareId,
              equipmentId: equipmentId,
              via: open.via,
              firstShareBootstrapRun: open.firstShareBootstrapRun,
              receivedAt: now().toUtc(),
            ),
          );
        }
      }),
    ]);
  }

  static Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {}
  }
}

final shareOpenRecorderProvider = Provider<ShareOpenRecorder>(
  (ref) => ShareOpenRecorder(
    analytics: ref.watch(analyticsServiceProvider),
    api: ref.watch(equipmentShareEventsApiProvider),
    isAuthenticated: () => ref.read(authProvider).isAuthenticated,
    firstTouch: ref.watch(equipmentShareFirstTouchStoreProvider),
  ),
);
