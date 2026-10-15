import 'dart:convert';
import 'dart:io';

import 'release.dart';

String secret(String name) {
  final value = Platform.environment[name];
  if (value == null || value.isEmpty) {
    blocked('Missing protected variable $name');
  }
  return value;
}

String propertiesValue(String value) => value
    .replaceAll('\\', '\\\\')
    .replaceAll('\r', '\\r')
    .replaceAll('\n', '\\n')
    .replaceAll('\t', '\\t')
    .replaceAll(' ', '\\ ')
    .replaceAll('=', '\\=')
    .replaceAll(':', '\\:');

void newFile(String path, List<int> bytes) {
  final file = File(path);
  if (file.existsSync()) {
    blocked('Refusing to overwrite existing CI input $path');
  }
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes, flush: true);
  if (!Platform.isWindows) {
    if (Process.runSync('chmod', ['600', file.path]).exitCode != 0) {
      blocked('Unable to restrict CI input permissions');
    }
  }
}

void main(List<String> args) {
  try {
    if (Platform.environment['CI'] != 'true' ||
        (Platform.environment['GITHUB_ACTIONS'] != 'true' &&
            (Platform.environment['CM_BUILD_ID'] ?? '').isEmpty)) {
      blocked(
        'Input materialization is only allowed in an ephemeral CI checkout',
      );
    }
    if (args.length != 1 || !{'android', 'ios'}.contains(args.single)) {
      blocked('Specify android or ios');
    }
    // Keep all endpoint/feature choices in Git. Only the public Mapbox token is
    // account-specific; do not accept arbitrary .env content from a CI secret.
    final config = Map<String, dynamic>.from(
      jsonDecode(File('tool/release/production.json').readAsStringSync())
          as Map,
    );
    final token = secret('MAPBOX_PUBLIC_TOKEN');
    if (!RegExp(r'^pk\.[A-Za-z0-9_.-]+$').hasMatch(token)) {
      blocked('MAPBOX_PUBLIC_TOKEN must be a public pk token');
    }
    config['MAPBOX_TOKEN'] = token;
    newFile(
      '.env',
      utf8.encode(config.entries.map((e) => '${e.key}=${e.value}\n').join()),
    );
    if (File('.env.local').existsSync() || File('config.json').existsSync()) {
      blocked('Local build overrides are forbidden in CI');
    }
    if (args.single == 'android') {
      final google = base64Decode(secret('GOOGLE_SERVICES_JSON_BASE64'));
      final json = jsonDecode(utf8.decode(google)) as Map;
      final clients = json['client'] as List;
      if (json['project_info']['project_id'] != 'prokat-bfbec' ||
          !clients.any(
            (dynamic c) =>
                c['client_info']['android_client_info']['package_name'] ==
                    'com.auyltech.prokat' &&
                c['client_info']['mobilesdk_app_id'] ==
                    '1:1074557540622:android:b034923095bf433d845f5f',
          )) {
        blocked('Firebase Android project/app identity mismatch');
      }
      newFile('android/app/google-services.json', google);
      newFile(
        'android/app/ci-upload.jks',
        base64Decode(secret('ANDROID_KEYSTORE_BASE64')),
      );
      final properties = {
        'storeFile': 'ci-upload.jks',
        'storePassword': secret('ANDROID_KEYSTORE_PASSWORD'),
        'keyAlias': secret('ANDROID_KEY_ALIAS'),
        'keyPassword': secret('ANDROID_KEY_PASSWORD'),
      };
      newFile(
        'android/key.properties',
        utf8.encode(
          properties.entries
              .map((e) => '${e.key}=${propertiesValue(e.value)}\n')
              .join(),
        ),
      );
      final play = base64Decode(secret('PLAY_SERVICE_ACCOUNT_JSON_BASE64'));
      final account = jsonDecode(utf8.decode(play)) as Map;
      if (account['type'] != 'service_account' ||
          account['private_key'] == null) {
        blocked('Play credentials must be a service account JSON');
      }
      newFile('build/release/play-service-account.json', play);
    } else {
      final plist = base64Decode(secret('GOOGLE_SERVICE_INFO_PLIST_BASE64'));
      newFile('ios/Runner/GoogleService-Info.plist', plist);
      // Native plist parsing/identity check is done by plutil on macOS, before
      // signing. The file is not assumed to be present in the Xcode project.
    }
    stdout.writeln('CI inputs prepared (values suppressed)');
  } on Object catch (error) {
    stderr.writeln(
      error is ReleaseFailure
          ? error
          : 'BLOCKED: Invalid CI inputs (${error.runtimeType}); values suppressed',
    );
    exitCode = 1;
  }
}
