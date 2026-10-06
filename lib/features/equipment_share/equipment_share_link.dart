import 'package:prokat/core/config/env.dart';
import 'package:prokat/features/equipment_share/equipment_share_id.dart';

class EquipmentShareLink {
  final String equipmentId;

  /// Query-free identity used for dedup, overlay and navigation.
  final Uri canonical;
  final String? shareId;

  const EquipmentShareLink({
    required this.equipmentId,
    required this.canonical,
    this.shareId,
  });

  /// [canonical] plus `?s=<shareId>` when the link carries a share id.
  Uri get uri {
    final id = shareId;
    return id == null
        ? canonical
        : canonical.replace(queryParameters: {'s': id});
  }

  static EquipmentShareLink? tryParse(Uri uri) {
    if (uri.scheme != 'https') return null;
    final host = uri.host.toLowerCase();
    if (!Env.shareTrustedHosts.contains(host)) return null;

    final segments = uri.pathSegments.where((part) => part.isNotEmpty).toList();
    if (segments.length != 2 || segments.first != 'e') return null;

    final id = Uri.decodeComponent(segments[1]).trim();
    if (id.isEmpty || id == '.' || id == '..' || id.contains('/')) return null;

    String? shareId;
    try {
      shareId = uri.queryParameters['s'];
    } catch (_) {}

    return EquipmentShareLink(
      equipmentId: id,
      canonical: Uri.https(host, '/e/${Uri.encodeComponent(id)}'),
      shareId: isValidShareId(shareId) ? shareId : null,
    );
  }
}
