import 'dart:async';

import 'package:prokat/core/analytics/analytics_service.dart';
import 'package:prokat/core/config/env.dart';
import 'package:prokat/features/equipment_share/equipment_share_events_api.dart';
import 'package:prokat/features/equipment_share/equipment_share_id.dart';
import 'package:prokat/features/equipment_share/equipment_share_result.dart';
import 'package:share_plus/share_plus.dart';

/// Registration is required for every attempt, including guests and retries.
/// Failures propagate to the existing localized error/retry UI.
Future<void> shareRegisteredEquipment({
  required String equipmentId,
  required EquipmentShareEventsApi api,
  required AnalyticsService analytics,
  required bool isAuthenticated,
  required Future<ShareResult?> Function(String url) openShareSheet,
  String Function() newShareId = generateShareId,
}) async {
  final shareId = newShareId();
  // Validate before creating a mapping; there is no equipment-ID URL builder.
  final url = Env.publicEquipmentShareUrl(shareId);
  await api.registerLink(shareId: shareId, equipmentId: equipmentId);
  final result = await openShareSheet(url);
  if (result == null) return;
  unawaited(
    reportShareResult(
      result: result,
      shareId: shareId,
      equipmentId: equipmentId,
      analytics: analytics,
      api: api,
      isAuthenticated: isAuthenticated,
    ),
  );
}
