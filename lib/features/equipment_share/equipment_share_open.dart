import 'dart:convert';

import 'package:prokat/core/analytics/analytics_events.dart';
import 'package:prokat/features/equipment_share/equipment_share_link.dart';

enum ShareOpenVia {
  appLink,
  installReferrer,
  deferredInstall;

  /// GA `open_via` value.
  String get wire => switch (this) {
    ShareOpenVia.appLink => AnalyticsValues.openViaAppLink,
    ShareOpenVia.installReferrer => AnalyticsValues.openViaInstallReferrer,
    ShareOpenVia.deferredInstall => 'deferred_install',
  };

  /// Backend `openVia` value.
  String? get api => switch (this) {
    ShareOpenVia.appLink => 'APP_LINK',
    ShareOpenVia.installReferrer => 'INSTALL_REFERRER',
    ShareOpenVia.deferredInstall => null,
  };
}

enum EquipmentShareIngressSource {
  legacyLink,
  appLink,
  installReferrer,
  deferredInstall,
}

/// An accepted incoming share link. Persisted as the pending open, so `via`
/// and [firstShareBootstrapRun] survive until the link is actually opened.
class EquipmentShareOpen {
  final EquipmentShareLink link;
  final ShareOpenVia via;
  final String? clientEventId;

  /// Diagnostic only: the link was handled by the share bootstrap run that
  /// found the install referrer still unchecked. Not "first install".
  final bool firstShareBootstrapRun;

  const EquipmentShareOpen({
    required this.link,
    required this.via,
    required this.firstShareBootstrapRun,
    this.clientEventId,
  });

  EquipmentShareIngressSource get source => switch (via) {
    ShareOpenVia.appLink =>
      link.isRegistryLink
          ? EquipmentShareIngressSource.appLink
          : EquipmentShareIngressSource.legacyLink,
    ShareOpenVia.installReferrer => EquipmentShareIngressSource.installReferrer,
    ShareOpenVia.deferredInstall => EquipmentShareIngressSource.deferredInstall,
  };

  EquipmentShareOpen resolved(String equipmentId) => EquipmentShareOpen(
    link: link.withEquipmentId(equipmentId),
    via: via,
    firstShareBootstrapRun: firstShareBootstrapRun,
    clientEventId: clientEventId,
  );

  EquipmentShareOpen withEventId(String id) => EquipmentShareOpen(
    link: link,
    via: via,
    firstShareBootstrapRun: firstShareBootstrapRun,
    clientEventId: id,
  );

  Map<String, dynamic> toJson() => {
    'v': link.isRegistryLink ? 2 : 1,
    'uri': link.uri.toString(),
    'via': via.wire,
    'firstShareBootstrapRun': firstShareBootstrapRun,
    if (clientEventId != null) 'clientEventId': clientEventId,
    if (link.isRegistryLink && link.equipmentId != null)
      'resolvedEquipmentId': link.equipmentId,
  };

  /// Reads the pending JSON; a legacy plain URI reads as `appLink`, `false`.
  static EquipmentShareOpen? tryParse(String raw) {
    try {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return null;

      if (!trimmed.startsWith('{')) {
        final link = EquipmentShareLink.tryParse(Uri.parse(trimmed));
        if (link == null) return null;
        return EquipmentShareOpen(
          link: link,
          via: ShareOpenVia.appLink,
          firstShareBootstrapRun: false,
        );
      }

      final decoded = jsonDecode(trimmed);
      if (decoded is! Map || (decoded['v'] != 1 && decoded['v'] != 2)) {
        return null;
      }
      final uri = decoded['uri'];
      final firstRun = decoded['firstShareBootstrapRun'];
      final eventId = decoded['clientEventId'];
      if (eventId != null &&
          (eventId is! String || !isShareIntentId(eventId))) {
        return null;
      }
      if (uri is! String || firstRun is! bool) return null;
      final via = _viaFromWire(decoded['via']);
      if (via == null) return null;
      var link = EquipmentShareLink.tryParse(Uri.parse(uri));
      if (link == null) return null;
      if (decoded['v'] == 2) {
        if (!link.isRegistryLink) return null;
        final target = decoded['resolvedEquipmentId'];
        if (target != null) {
          if (target is! String ||
              !EquipmentShareLink.isValidEquipmentId(target)) {
            return null;
          }
          link = link.withEquipmentId(target);
        }
      } else if (link.isRegistryLink) {
        return null;
      }
      return EquipmentShareOpen(
        link: link,
        via: via,
        firstShareBootstrapRun: firstRun,
        clientEventId: eventId as String?,
      );
    } catch (_) {
      return null;
    }
  }
}

bool isShareIntentId(String value) => RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
).hasMatch(value);

ShareOpenVia? _viaFromWire(Object? value) {
  for (final via in ShareOpenVia.values) {
    if (via.wire == value) return via;
  }
  return null;
}
