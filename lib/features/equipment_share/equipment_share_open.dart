import 'dart:convert';

import 'package:prokat/core/analytics/analytics_events.dart';
import 'package:prokat/features/equipment_share/equipment_share_link.dart';

enum ShareOpenVia {
  appLink,
  installReferrer;

  /// GA `open_via` value.
  String get wire => switch (this) {
    ShareOpenVia.appLink => AnalyticsValues.openViaAppLink,
    ShareOpenVia.installReferrer => AnalyticsValues.openViaInstallReferrer,
  };

  /// Backend `openVia` value.
  String get api => switch (this) {
    ShareOpenVia.appLink => 'APP_LINK',
    ShareOpenVia.installReferrer => 'INSTALL_REFERRER',
  };
}

/// An accepted incoming share link. Persisted as the pending open, so `via`
/// and [firstShareBootstrapRun] survive until the link is actually opened.
class EquipmentShareOpen {
  final EquipmentShareLink link;
  final ShareOpenVia via;

  /// Diagnostic only: the link was handled by the share bootstrap run that
  /// found the install referrer still unchecked. Not "first install".
  final bool firstShareBootstrapRun;

  const EquipmentShareOpen({
    required this.link,
    required this.via,
    required this.firstShareBootstrapRun,
  });

  Map<String, dynamic> toJson() => {
    'v': 1,
    'uri': link.uri.toString(),
    'via': via.wire,
    'firstShareBootstrapRun': firstShareBootstrapRun,
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
      if (decoded is! Map || decoded['v'] != 1) return null;
      final uri = decoded['uri'];
      final firstRun = decoded['firstShareBootstrapRun'];
      if (uri is! String || firstRun is! bool) return null;
      final via = _viaFromWire(decoded['via']);
      if (via == null) return null;
      final link = EquipmentShareLink.tryParse(Uri.parse(uri));
      if (link == null) return null;
      return EquipmentShareOpen(
        link: link,
        via: via,
        firstShareBootstrapRun: firstRun,
      );
    } catch (_) {
      return null;
    }
  }
}

ShareOpenVia? _viaFromWire(Object? value) {
  for (final via in ShareOpenVia.values) {
    if (via.wire == value) return via;
  }
  return null;
}
