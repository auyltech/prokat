import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:play_install_referrer/play_install_referrer.dart';
import 'package:prokat/core/config/env.dart';
import 'package:prokat/features/equipment_share/equipment_share_link.dart';

/// Play returns either a share URL or `id=<equipmentId>` from the install page.
EquipmentShareLink? shareLinkFromInstallReferrer(String? raw) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty) return null;

  final asUri = Uri.tryParse(value);
  if (asUri != null && asUri.hasScheme) {
    final link = EquipmentShareLink.tryParse(asUri);
    if (link != null) return link;
  }

  final Map<String, String> params;
  try {
    params = Uri.splitQueryString(
      value.startsWith('?') ? value.substring(1) : value,
    );
  } catch (_) {
    return null;
  }

  final id = (params['id'] ?? '').trim();
  if (id.isEmpty) return null;

  final base = Uri.parse(Env.shareBaseUrl);
  return EquipmentShareLink.tryParse(
    base.replace(path: '/e/${Uri.encodeComponent(id)}'),
  );
}

/// Reads the Play install referrer once. A thrown error means Play was not
/// ready — the caller must not mark the check done. Non-Android returns null
/// so the check can be marked without opening a card.
Future<String?> readPlayInstallReferrer() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return null;
  }

  final details = await PlayInstallReferrer.installReferrer;
  final raw = details.installReferrer?.trim();
  if (raw == null || raw.isEmpty) return null;
  return raw;
}

/// Returns a share link from the install referrer, or null when there is
/// nothing to open. Does not mark the check when [readReferrer] throws.
Future<EquipmentShareLink?> captureShareInstallReferrer({
  required Future<bool> Function() wasChecked,
  required Future<void> Function() markChecked,
  required Future<String?> Function() readReferrer,
}) async {
  if (await wasChecked()) return null;

  final String? raw;
  try {
    raw = await readReferrer();
  } on PlatformException {
    return null;
  } catch (_) {
    return null;
  }

  await markChecked();
  return shareLinkFromInstallReferrer(raw);
}
