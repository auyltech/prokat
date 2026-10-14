import 'package:version/version.dart';

enum AppUpdatePolicy { upToDate, silent, soft, hard }

/// Parse a complete SemVer and retain only major.minor.patch for policy.
/// The library accepts abbreviated versions, so require the complete core here.
Version? parseAppVersion(String? raw) {
  final value = raw?.trim() ?? '';
  final match = RegExp(
    r'^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?(?:\+([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?$',
  ).firstMatch(value);
  if (match == null ||
      (match
              .group(4)
              ?.split('.')
              .any(
                (part) =>
                    RegExp(r'^\d+$').hasMatch(part) &&
                    part.length > 1 &&
                    part.startsWith('0'),
              ) ??
          false)) {
    return null;
  }
  try {
    final parsed = Version.parse(value);
    return Version(parsed.major, parsed.minor, parsed.patch);
  } on FormatException {
    return null;
  } on ArgumentError {
    return null;
  }
}

Version? effectiveAppMinimum({String? remote, String? store}) {
  final remoteVersion = parseAppVersion(remote);
  final storeVersion = parseAppVersion(store);
  if (remoteVersion == null) return storeVersion;
  if (storeVersion == null) return remoteVersion;
  return remoteVersion > storeVersion ? remoteVersion : storeVersion;
}

AppUpdatePolicy classifyAppUpdate({
  required String? installed,
  required String? latest,
  String? minimum,
}) {
  final current = parseAppVersion(installed);
  if (current == null) return AppUpdatePolicy.upToDate;
  final floor = parseAppVersion(minimum);
  if (floor != null && current < floor) return AppUpdatePolicy.hard;
  final available = parseAppVersion(latest);
  if (available == null || available <= current) {
    return AppUpdatePolicy.upToDate;
  }
  if (available.major > current.major) return AppUpdatePolicy.hard;
  if (available.minor > current.minor) return AppUpdatePolicy.soft;
  return AppUpdatePolicy.silent;
}
