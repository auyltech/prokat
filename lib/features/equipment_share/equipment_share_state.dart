import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:prokat/core/config/env.dart';
import 'package:prokat/features/equipment_share/equipment_share_booking_intent.dart';
import 'package:prokat/features/equipment_share/equipment_share_open.dart';
import 'package:prokat/features/equipment_share/equipment_share_overlay.dart';

String shareStorageKey(String key) => Env.isLocal ? 'local_$key' : key;

Future<String> readSharePrivacyEpoch(FlutterSecureStorage storage) async {
  final marker = await storage.read(
    key: shareStorageKey('equipment_share_privacy_epoch'),
  );
  final raw = await storage.read(key: shareStorageKey('equipment_share_state'));
  String? stateEpoch;
  if (raw != null) {
    try {
      final data = jsonDecode(raw);
      final epoch = data is Map && data['v'] == 3 ? data['epoch'] : null;
      if (epoch is String && isSharePrivacyEpoch(epoch)) stateEpoch = epoch;
    } catch (_) {}
  }
  if (marker != null && !isSharePrivacyEpoch(marker)) {
    throw const FormatException('Invalid share epoch');
  }
  if (marker == null) return stateEpoch ?? '0';
  if (stateEpoch == null ||
      sharePrivacyRevision(marker) >= sharePrivacyRevision(stateEpoch)) {
    return marker;
  }
  return stateEpoch;
}

int sharePrivacyRevision(String epoch) =>
    int.tryParse(epoch.split(':').first) ?? 0;

bool isSharePrivacyEpoch(String epoch) {
  if (epoch == '0' || isShareIntentId(epoch)) return true;
  final pieces = epoch.split(':');
  return pieces.length == 2 &&
      RegExp(r'^[1-9][0-9]{0,14}$').hasMatch(pieces.first) &&
      isShareIntentId(pieces.last);
}

/// One secure-storage replacement commits correlated routing and attribution.
class EquipmentShareState {
  const EquipmentShareState({
    required this.epoch,
    this.intentId,
    this.open,
    this.pending = false,
    this.overlay,
    this.bookingIntent,
    this.openedPending = false,
    this.analyticsClaimed = false,
    this.bookingAttributionConsumed = false,
    this.receivedAt,
    this.installReferrerChecked = false,
  });

  final String epoch;
  final String? intentId;
  final EquipmentShareOpen? open;
  final bool pending;
  final EquipmentShareOverlay? overlay;
  final EquipmentShareBookingIntent? bookingIntent;
  final bool openedPending;
  final bool analyticsClaimed;
  final bool bookingAttributionConsumed;
  final DateTime? receivedAt;
  final bool installReferrerChecked;

  bool get actionable => pending || overlay != null;

  EquipmentShareState copyWith({
    EquipmentShareOverlay? overlay,
    bool clearOverlay = false,
    EquipmentShareBookingIntent? bookingIntent,
    bool clearBookingIntent = false,
    bool? openedPending,
    bool? analyticsClaimed,
    bool? bookingAttributionConsumed,
    bool? installReferrerChecked,
  }) => EquipmentShareState(
    epoch: epoch,
    intentId: intentId,
    open: open,
    pending: pending,
    overlay: clearOverlay ? null : overlay ?? this.overlay,
    bookingIntent: clearBookingIntent
        ? null
        : bookingIntent ?? this.bookingIntent,
    openedPending: openedPending ?? this.openedPending,
    analyticsClaimed: analyticsClaimed ?? this.analyticsClaimed,
    bookingAttributionConsumed:
        bookingAttributionConsumed ?? this.bookingAttributionConsumed,
    receivedAt: receivedAt,
    installReferrerChecked:
        installReferrerChecked ?? this.installReferrerChecked,
  );

  String encode() => jsonEncode({
    'v': 3,
    'epoch': epoch,
    'intentId': intentId,
    'open': open?.toJson(),
    'pending': pending,
    'overlay': overlay?.toJson(),
    'bookingIntent': bookingIntent?.toJson(),
    'openedPending': openedPending,
    'analyticsClaimed': analyticsClaimed,
    'bookingAttributionConsumed': bookingAttributionConsumed,
    'receivedAt': receivedAt?.toUtc().toIso8601String(),
    'installReferrerChecked': installReferrerChecked,
  });

  static EquipmentShareState? tryParse(String raw, String epoch) {
    try {
      final data = jsonDecode(raw);
      if (data is! Map ||
          data['v'] != 3 ||
          data['epoch'] != epoch ||
          data['pending'] is! bool ||
          data['openedPending'] is! bool ||
          data['analyticsClaimed'] is! bool ||
          (data['bookingAttributionConsumed'] != null &&
              data['bookingAttributionConsumed'] is! bool)) {
        return null;
      }
      if (data['installReferrerChecked'] != null &&
          data['installReferrerChecked'] is! bool) {
        return null;
      }
      final id = data['intentId'];
      if (id != null && (id is! String || !isShareIntentId(id))) return null;
      final open = data['open'] == null
          ? null
          : EquipmentShareOpen.tryParse(jsonEncode(data['open']));
      final overlay = data['overlay'] == null
          ? null
          : EquipmentShareOverlay.tryParse(jsonEncode(data['overlay']));
      final intent = data['bookingIntent'] == null
          ? null
          : EquipmentShareBookingIntent.tryParse(
              jsonEncode(data['bookingIntent']),
            );
      final at = data['receivedAt'] == null
          ? null
          : DateTime.tryParse(data['receivedAt'] as String);
      if ((data['open'] != null && open == null) ||
          (data['overlay'] != null && overlay == null) ||
          (data['bookingIntent'] != null && intent == null) ||
          (data['receivedAt'] != null && at == null)) {
        return null;
      }
      final pending = data['pending'] as bool;
      final openedPending = data['openedPending'] as bool;
      if ((open != null || overlay != null || intent != null) && id == null) {
        return null;
      }
      if (open != null && (open.clientEventId != id || at == null)) return null;
      final bookingConsumed = data['bookingAttributionConsumed'] == true;
      if (pending &&
          (open == null ||
              overlay != null ||
              openedPending ||
              bookingConsumed)) {
        return null;
      }
      if (!pending && open != null && open.link.equipmentId == null) {
        return null;
      }
      if (openedPending && open == null) return null;
      if (bookingConsumed && open == null) return null;
      if (overlay != null &&
          open != null &&
          overlay.equipmentId != open.link.equipmentId) {
        return null;
      }
      if (intent != null &&
          intent.equipmentId !=
              (open?.link.equipmentId ??
                  overlay?.equipmentId ??
                  intent.equipmentId)) {
        return null;
      }
      return EquipmentShareState(
        epoch: epoch,
        intentId: id as String?,
        open: open,
        pending: pending,
        overlay: overlay,
        bookingIntent: intent,
        openedPending: openedPending,
        analyticsClaimed: data['analyticsClaimed'] as bool,
        bookingAttributionConsumed: bookingConsumed,
        receivedAt: at?.toUtc(),
        installReferrerChecked: data['installReferrerChecked'] == true,
      );
    } catch (_) {
      return null;
    }
  }
}
