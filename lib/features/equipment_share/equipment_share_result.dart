import 'dart:async';

import 'package:prokat/core/analytics/analytics_service.dart';
import 'package:prokat/features/equipment_share/equipment_share_events_api.dart';
import 'package:prokat/features/equipment_share/equipment_share_id.dart';
import 'package:share_plus/share_plus.dart';

/// Only a platform-confirmed [ShareResultStatus.success] counts as a share.
Future<void> reportShareResult({
  required ShareResult result,
  required String shareId,
  required String equipmentId,
  required AnalyticsService analytics,
  required EquipmentShareEventsApi api,
  required bool isAuthenticated,
}) async {
  if (result.status != ShareResultStatus.success) return;
  final method = shareMethodFromRaw(result.raw);
  unawaited(
    analytics.logShare(
      equipmentId: equipmentId,
      shareId: shareId,
      method: method,
    ),
  );
  if (isAuthenticated) {
    unawaited(
      api.recordShared(
        shareId: shareId,
        equipmentId: equipmentId,
        method: method,
      ),
    );
  }
}
