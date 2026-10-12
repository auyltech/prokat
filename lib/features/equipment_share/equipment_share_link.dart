import 'package:prokat/core/config/env.dart';
import 'package:prokat/features/equipment_share/equipment_share_id.dart';

class EquipmentShareLink {
  final String? equipmentId;
  static const appOpenHost = 'open.prokat.auyltech.kz';
  static final _equipmentIdPattern = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

  /// Trusted query-free URL; the registry form contains the share token.
  final Uri canonical;
  final String? shareId;

  const EquipmentShareLink({
    required this.equipmentId,
    required this.canonical,
    this.shareId,
  });

  bool get isRegistryLink => canonical.host == appOpenHost;

  static bool isValidEquipmentId(String? id) =>
      id != null && _equipmentIdPattern.hasMatch(id);

  factory EquipmentShareLink.fromShareId(String shareId) {
    if (!isValidShareId(shareId)) throw ArgumentError('Invalid share token');
    return EquipmentShareLink(
      equipmentId: null,
      canonical: Uri.https(appOpenHost, '/e/$shareId'),
      shareId: shareId,
    );
  }

  EquipmentShareLink withEquipmentId(String id) {
    if (!isValidEquipmentId(id)) {
      throw ArgumentError('Invalid equipment target');
    }
    return EquipmentShareLink(
      equipmentId: id,
      canonical: canonical,
      shareId: shareId,
    );
  }

  /// Registry token URL, or the legacy URL plus its optional `?s=<shareId>`.
  Uri get uri {
    if (isRegistryLink) return canonical;
    final id = shareId;
    return id == null
        ? canonical
        : canonical.replace(queryParameters: {'s': id});
  }

  static EquipmentShareLink? tryParse(Uri uri) {
    if (uri.scheme != 'https' || uri.userInfo.isNotEmpty || uri.port != 443) {
      return null;
    }
    final host = uri.host.toLowerCase();
    if (host == 'prokat.auyltech.kz') return null;
    if (host == appOpenHost) {
      if (uri.hasFragment ||
          !RegExp(r'^/e/[A-Za-z0-9_-]{22}$').hasMatch(uri.path)) {
        return null;
      }
      return EquipmentShareLink.fromShareId(uri.path.substring(3));
    }
    if (!Env.shareTrustedHosts.contains(host)) return null;

    final segments = uri.pathSegments.where((part) => part.isNotEmpty).toList();
    if (segments.length != 2 || segments.first != 'e') return null;

    final id = segments[1];
    if (!isValidEquipmentId(id)) return null;

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
