import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/analytics/analytics_client.dart';
import 'package:prokat/core/analytics/analytics_events.dart';
import 'package:prokat/core/analytics/firebase_analytics_client.dart';
import 'package:prokat/core/config/env.dart';
import 'package:prokat/features/catalog/models/catalog_group.dart';

class AnalyticsService {
  AnalyticsService(this._client);

  final AnalyticsClient _client;

  Future<void> logSignUp({String? shareId}) => _log(AnalyticsEvents.signUp, {
    AnalyticsParams.method: AnalyticsValues.methodPhoneOtp,
    AnalyticsParams.shareId: shareId,
  });

  Future<void> logOwnerApplicationStarted() =>
      _log(AnalyticsEvents.ownerApplicationStarted, const {});

  Future<void> logOwnerApplicationSubmitted({required bool isResubmit}) => _log(
    AnalyticsEvents.ownerApplicationSubmitted,
    {AnalyticsParams.isResubmit: isResubmit},
  );

  Future<void> logEquipmentCreationStarted({bool? isFirstEquipment}) => _log(
    AnalyticsEvents.equipmentCreationStarted,
    {AnalyticsParams.isFirstEquipment: isFirstEquipment},
  );

  Future<void> logEquipmentDraftCreated({
    required String categoryId,
    required CatalogGroup group,
    bool? isFirstEquipment,
  }) => _log(AnalyticsEvents.equipmentDraftCreated, {
    AnalyticsParams.categoryId: categoryId,
    AnalyticsParams.catalogGroup: _catalogGroupValue(group),
    AnalyticsParams.isFirstEquipment: isFirstEquipment,
  });

  Future<void> logEquipmentSubmittedForReview({
    required bool isResubmit,
    String? categoryId,
    CatalogGroup? group,
  }) => _log(AnalyticsEvents.equipmentSubmittedForReview, {
    AnalyticsParams.isResubmit: isResubmit,
    AnalyticsParams.categoryId: categoryId,
    AnalyticsParams.catalogGroup: group == null
        ? null
        : _catalogGroupValue(group),
  });

  Future<void> logShare({
    required String equipmentId,
    required String shareId,
    required String method,
  }) => _log(AnalyticsEvents.share, {
    AnalyticsParams.contentType: AnalyticsValues.contentTypeEquipment,
    AnalyticsParams.itemId: equipmentId,
    AnalyticsParams.shareId: shareId,
    AnalyticsParams.method: method,
  });

  Future<void> logScreenView(String screenName) async {
    try {
      await _client.logScreenView(screenName);
    } catch (_) {}
  }

  Future<void> _log(String name, Map<String, Object?> params) async {
    try {
      final sanitized = <String, Object>{
        for (final entry in params.entries)
          if (entry.value != null) entry.key: _toWire(entry.value!),
      };
      await _client.logEvent(name, sanitized);
    } catch (_) {}
  }

  static Object _toWire(Object value) =>
      value is bool ? (value ? 1 : 0) : value;

  static String _catalogGroupValue(CatalogGroup group) => switch (group) {
    CatalogGroup.machinery => AnalyticsValues.catalogGroupMachinery,
    CatalogGroup.equipment => AnalyticsValues.catalogGroupEquipment,
  };
}

final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => AnalyticsService(
    Env.firebaseServicesEnabled
        ? FirebaseAnalyticsClient()
        : const NoopAnalyticsClient(),
  ),
);
