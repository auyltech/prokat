import 'package:prokat/core/config/env.dart';

class EquipmentShareLink {
  final String equipmentId;
  final Uri canonical;

  const EquipmentShareLink({
    required this.equipmentId,
    required this.canonical,
  });

  static EquipmentShareLink? tryParse(Uri uri) {
    if (uri.scheme != 'https') return null;
    final host = uri.host.toLowerCase();
    if (!Env.shareTrustedHosts.contains(host)) return null;

    final segments = uri.pathSegments.where((part) => part.isNotEmpty).toList();
    if (segments.length != 2 || segments.first != 'e') return null;

    final id = Uri.decodeComponent(segments[1]).trim();
    if (id.isEmpty || id == '.' || id == '..' || id.contains('/')) return null;

    return EquipmentShareLink(
      equipmentId: id,
      canonical: Uri.https(host, '/e/${Uri.encodeComponent(id)}'),
    );
  }
}
