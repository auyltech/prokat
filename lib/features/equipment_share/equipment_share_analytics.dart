import 'package:flutter/foundation.dart';

abstract final class EquipmentShareAnalytics {
  static void shareStarted(String equipmentId) {
    debugPrint('equipment_share started equipmentId=$equipmentId');
  }

  static void shareCompleted(String equipmentId) {
    debugPrint('equipment_share completed equipmentId=$equipmentId');
  }

  static void shareFailed(String equipmentId) {
    debugPrint('equipment_share failed equipmentId=$equipmentId');
  }
}
