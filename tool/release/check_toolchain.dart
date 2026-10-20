import 'dart:convert';
import 'dart:io';

import 'release.dart';

void validateIosLock(String lock) {
  // This project already uses SwiftPM. CocoaPods locks only fallback plugins;
  // Firebase and Mapbox are legitimately absent from Podfile.lock.
  if (!lock.contains('  - Flutter (')) {
    blocked('Missing Flutter fallback pod in ios/Podfile.lock');
  }
  if (!lock.contains('COCOAPODS: 1.16.2')) {
    blocked('Native lock must be generated with the pinned CocoaPods 1.16.2');
  }
}

Map<String, String> validateIosSwiftLock(String lock) {
  final data = jsonDecode(lock) as Map;
  if (!{2, 3}.contains(data['version']) || data['pins'] is! List) {
    blocked('Unsupported/malformed Swift Package.resolved');
  }
  final pins = <String, String>{};
  for (final raw in data['pins'] as List) {
    final pin = raw as Map;
    final identity = pin['identity'] as String;
    final state = pin['state'] as Map;
    final revision = state['revision'] as String? ?? '';
    if (!RegExp(r'^[a-f0-9]{40}$').hasMatch(revision) ||
        pins.containsKey(identity)) {
      blocked('Unpinned/duplicate Swift package: $identity');
    }
    pins[identity] = '${pin['location']}@${state['version']}#$revision';
  }
  for (final required in ['firebase-ios-sdk', 'mapbox-maps-ios']) {
    if (!pins.containsKey(required)) {
      blocked('Missing native Swift package: $required');
    }
  }
  return pins;
}

void validateIosNativeLocks() {
  validateIosLock(File('ios/Podfile.lock').readAsStringSync());
  final workspace = validateIosSwiftLock(
    File('ios/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved')
        .readAsStringSync(),
  );
  final project = validateIosSwiftLock(
    File(
      'ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved',
    ).readAsStringSync(),
  );
  if (workspace.length != project.length ||
      workspace.entries.any((entry) => project[entry.key] != entry.value)) {
    blocked('Workspace/project Swift Package.resolved pins disagree');
  }
}

void main(List<String> args) {
  try {
    if (args.length == 1 && args.single == 'ios-lock') {
      validateIosNativeLocks();
      stdout.writeln(
        'VERIFIED: CocoaPods fallback metadata and both native Swift lock graphs',
      );
      return;
    }
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
      validateIosNativeLocks();
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
