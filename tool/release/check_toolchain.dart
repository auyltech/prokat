import 'dart:convert';
import 'dart:io';

import 'release.dart';

void validateIosLock(String lock) {
  for (final pod in [
    'firebase_core',
    'firebase_crashlytics',
    'firebase_messaging',
    'mapbox_maps_flutter',
  ]) {
    if (!lock.contains('  - $pod (')) {
      blocked(
        'ios/Podfile.lock is incomplete ($pod missing). Resolve on supported macOS, review and commit before U4',
      );
    }
  }
  if (!lock.contains('COCOAPODS: 1.16.2')) {
    blocked('Native lock must be generated with the pinned CocoaPods 1.16.2');
  }
}

void main(List<String> args) {
  try {
    final version = File('.flutter-version').readAsStringSync().trim();
    final fvm = jsonDecode(File('.fvmrc').readAsStringSync()) as Map;
    final pubspec = File('pubspec.yaml').readAsStringSync();
    if (version != fvm['flutter'] || !pubspec.contains('flutter: $version')) {
      blocked('Flutter pins disagree: .flutter-version, .fvmrc, pubspec.yaml');
    }
    final result = Process.runSync(
      Platform.isWindows ? 'flutter.bat' : 'flutter',
      ['--version', '--machine'],
      runInShell: Platform.isWindows,
    );
    if (result.exitCode != 0) blocked('Cannot identify installed Flutter');
    final actual = jsonDecode(result.stdout as String) as Map;
    if (actual['frameworkVersion'] != version) {
      blocked('Runner Flutter does not match pinned SDK');
    }
    stdout.writeln('SDK ${jsonEncode(actual)}');
    if (args.contains('ios')) {
      validateIosLock(File('ios/Podfile.lock').readAsStringSync());
    }
  } on Object catch (error) {
    stderr.writeln(
      error is ReleaseFailure
          ? error
          : 'BLOCKED: Toolchain check failed (${error.runtimeType})',
    );
    exitCode = 1;
  }
}
