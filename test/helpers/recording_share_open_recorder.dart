import 'package:dio/dio.dart';
import 'package:prokat/core/analytics/analytics_service.dart';
import 'package:prokat/features/equipment_share/equipment_share_events_api.dart';
import 'package:prokat/features/equipment_share/equipment_share_first_touch.dart';
import 'package:prokat/features/equipment_share/equipment_share_open.dart';
import 'package:prokat/features/equipment_share/equipment_share_open_recorder.dart';

import 'recording_analytics_client.dart';

class RecordingShareOpenRecorder extends ShareOpenRecorder {
  RecordingShareOpenRecorder()
    : super(
        analytics: AnalyticsService(RecordingAnalyticsClient()),
        api: EquipmentShareEventsApi(Dio()),
        firstTouch: EquipmentShareFirstTouchStore(),
        isAuthenticated: () => false,
      );

  final opens = <EquipmentShareOpen>[];

  @override
  Future<bool> record(
    EquipmentShareOpen open, {
    bool emitAnalytics = true,
    bool Function()? isCurrent,
  }) async {
    if (!(isCurrent?.call() ?? true)) return false;
    opens.add(open);
    return true;
  }
}
