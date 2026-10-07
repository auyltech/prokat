import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

final _shareIdPattern = RegExp(r'^[A-Za-z0-9_-]{22}$');

/// 16 random bytes as unpadded base64url: exactly 22 chars, new per share act.
String generateShareId({Random? random}) {
  final source = random ?? Random.secure();
  final bytes = Uint8List(16);
  for (var i = 0; i < bytes.length; i++) {
    bytes[i] = source.nextInt(256);
  }
  return base64Url.encode(bytes).replaceAll('=', '');
}

bool isValidShareId(String? value) =>
    value != null && _shareIdPattern.hasMatch(value);

/// Maps `ShareResult.raw` (Android component / iOS activity type) to the
/// backend `method` enum without leaking raw app identifiers.
String shareMethodFromRaw(String raw) {
  final value = raw.toLowerCase();
  if (value.isEmpty) return 'unknown';
  if (value.contains('whatsapp')) return 'whatsapp';
  if (value.contains('telegra')) return 'telegram';
  if (value.contains('instagram')) return 'instagram';
  if (value.contains('copytopasteboard')) return 'copy';
  return 'other';
}
