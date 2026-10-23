import 'dart:convert';
import 'dart:io';

import 'release.dart';

void requireTargetSdk(String dumped, {int minimum = 36}) {
  final parsed = int.tryParse(dumped.trim());
  if (parsed == null || parsed < minimum) {
    blocked('AAB targetSdkVersion must be at least $minimum');
  }
}

String invoke(String executable, List<String> args) {
  final result = Process.runSync(executable, args);
  if (result.exitCode != 0) {
    blocked('Android artifact verification failed: $executable');
  }
  return '${result.stdout}\n${result.stderr}';
}

void main(List<String> args) {
  try {
    if (args.length != 1) blocked('Specify the verified bundletool jar');
    final context = jsonDecode(
      File('build/release/context.json').readAsStringSync(),
    ) as Map;
    const aab = 'build/app/outputs/bundle/release/app-release.aab';
    final signature = invoke('jarsigner', [
      '-J-Duser.language=en',
      '-verify',
      aab,
    ]);
    if (!signature.contains('jar verified.')) blocked('AAB is not signed');
    final fingerprint =
        (Platform.environment['ANDROID_UPLOAD_CERT_SHA256'] ?? '')
            .replaceAll(':', '')
            .toUpperCase();
    if (!RegExp(r'^[A-F0-9]{64}$').hasMatch(fingerprint)) {
      blocked('U2 must confirm the existing upload certificate SHA256');
    }
    final certificate = invoke('keytool', [
      '-J-Duser.language=en',
      '-printcert',
      '-jarfile',
      aab,
    ]);
    final found = RegExp(r'SHA256: ([A-Fa-f0-9:]+)')
        .firstMatch(certificate)?[1]
        ?.replaceAll(':', '')
        .toUpperCase();
    if (found != fingerprint || certificate.contains('CN=Android Debug')) {
      blocked('AAB upload signing identity mismatch/debug certificate');
    }
    invoke('java', ['-jar', args.single, 'validate', '--bundle=$aab']);
    for (final attribute in {
      'package': 'com.auyltech.prokat',
      'android:versionCode': '${context['build']}',
      'android:versionName': '${context['version']}',
    }.entries) {
      final value = invoke('java', [
        '-jar',
        args.single,
        'dump',
        'manifest',
        '--bundle=$aab',
        '--xpath=/manifest/@${attribute.key}',
      ]).trim();
      if (value != attribute.value) {
        blocked('AAB ${attribute.key} differs from tag/project identity');
      }
    }
    requireTargetSdk(
      invoke('java', [
        '-jar',
        args.single,
        'dump',
        'manifest',
        '--bundle=$aab',
        '--xpath=/manifest/uses-sdk/@android:targetSdkVersion',
      ]),
    );
    stdout.writeln(
      'VERIFIED: AAB structure, signature fingerprint, package, versionName/versionCode, targetSdk',
    );
  } on Object catch (error) {
    stderr.writeln(
      error is ReleaseFailure
          ? error
          : 'BLOCKED: Android artifact validation failed (${error.runtimeType})',
    );
    exitCode = 1;
  }
}
