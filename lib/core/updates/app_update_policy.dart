import 'package:version/version.dart';

enum AppUpdatePolicy { upToDate, silent, soft, hard }

enum AppUpdateReason { none, forcedVersion, minimum, major, minor, patch }

enum AppUpdateDiagnostic {
  forcedVersionWithoutNewerStore,
  minimumWithoutSupportedStore,
}

class AppUpdateDecision {
  const AppUpdateDecision(this.policy, this.reason, this.diagnostics);
  final AppUpdatePolicy policy;
  final AppUpdateReason reason;
  final List<AppUpdateDiagnostic> diagnostics;
}

/// A stable semantic version, optionally qualified by an exact native build.
class ForcedAppVersion {
  const ForcedAppVersion(this.version, {this.build});
  final Version version;
  final String? build;

  static ForcedAppVersion? tryParse(String raw) {
    final value = raw.trim();
    // Force syntax deliberately excludes prereleases and internal whitespace.
    if (!RegExp(r'^\d+\.\d+\.\d+(?:\+[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?$')
        .hasMatch(value)) {
      return null;
    }
    final version = parseAppVersion(value);
    if (version == null) return null;
    final separator = value.indexOf('+');
    return ForcedAppVersion(
      version,
      build: separator < 0 ? null : value.substring(separator + 1),
    );
  }

  bool matches(Version installed, String? installedBuild) =>
      version == installed &&
      (build == null || build == installedBuild?.trim());

  @override
  String toString() => '$version${build == null ? '' : '+$build'}';

  @override
  bool operator ==(Object other) =>
      other is ForcedAppVersion &&
      other.version == version &&
      other.build == build;

  @override
  int get hashCode => Object.hash(version, build);
}

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
  String? installedBuild,
  List<ForcedAppVersion> forcedVersions = const [],
}) => evaluateAppUpdate(
  installed: installed,
  installedBuild: installedBuild,
  latest: latest,
  minimum: minimum,
  forcedVersions: forcedVersions,
).policy;

/// Store adapters do not expose a reliable Store build number. Only a strictly
/// newer semantic version proves availability; Remote Config cannot invent it.
AppUpdateDecision evaluateAppUpdate({
  required String? installed,
  required String? latest,
  String? installedBuild,
  String? minimum,
  List<ForcedAppVersion> forcedVersions = const [],
}) {
  final current = parseAppVersion(installed);
  if (current == null) {
    return const AppUpdateDecision(
      AppUpdatePolicy.upToDate,
      AppUpdateReason.none,
      [],
    );
  }
  final available = parseAppVersion(latest);
  final newer = available != null && available > current;
  final diagnostics = <AppUpdateDiagnostic>[];
  final forced = forcedVersions.any(
    (rule) => rule.matches(current, installedBuild),
  );
  if (forced) {
    if (newer) {
      return const AppUpdateDecision(
        AppUpdatePolicy.hard,
        AppUpdateReason.forcedVersion,
        [],
      );
    }
    diagnostics.add(AppUpdateDiagnostic.forcedVersionWithoutNewerStore);
  }
  final floor = parseAppVersion(minimum);
  if (floor != null && current < floor) {
    if (newer && available >= floor) {
      return AppUpdateDecision(
        AppUpdatePolicy.hard,
        AppUpdateReason.minimum,
        diagnostics,
      );
    }
    diagnostics.add(AppUpdateDiagnostic.minimumWithoutSupportedStore);
  }
  final policy = !newer
      ? AppUpdatePolicy.upToDate
      : available.major > current.major
      ? AppUpdatePolicy.hard
      : available.minor > current.minor
      ? AppUpdatePolicy.soft
      : AppUpdatePolicy.silent;
  final reason = switch (policy) {
    AppUpdatePolicy.upToDate => AppUpdateReason.none,
    AppUpdatePolicy.hard => AppUpdateReason.major,
    AppUpdatePolicy.soft => AppUpdateReason.minor,
    AppUpdatePolicy.silent => AppUpdateReason.patch,
  };
  return AppUpdateDecision(policy, reason, List.unmodifiable(diagnostics));
}
