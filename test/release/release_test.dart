import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/release/release.dart' as release;
import '../../tool/release/check_toolchain.dart' as toolchain;
import '../../tool/release/inputs.dart' as inputs;

void main() {
  test('new platform attempts use common numbers across both platforms', () {
    final tag = release.ReleaseTag.parse('ios/v1.8.0+108');
    release.validateBuildHistory(tag, [
      'rc/ios/v1.8.0+107',
      'android/v1.8.0+106',
      tag.tag,
      'archive/old',
    ]);
    expect(
      () => release.validateBuildHistory(tag, ['android/v1.8.0+999']),
      throwsA(isA<release.ReleaseFailure>()),
    );
    expect(
      () => release.validateBuildHistory(tag, ['rc/ios/v1.8.0+108']),
      throwsA(isA<release.ReleaseFailure>()),
    );
    expect(
      () => release.validateBuildHistory(tag, ['rc/ios/v1.8.0+109']),
      throwsA(isA<release.ReleaseFailure>()),
    );
    const same = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
    const other = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
    release.validateBuildHistory(
      release.ReleaseTag.parse('ios/v1.2.3+25'),
      ['android/v1.2.3+25'],
      revision: same,
      commits: {'android/v1.2.3+25': same},
    );
    release.validateBuildHistory(
      release.ReleaseTag.parse('rc/android/v1.2.3+24'),
      ['rc/ios/v1.2.3+24'],
      revision: same,
      commits: {'rc/ios/v1.2.3+24': same},
    );
    expect(
      () => release.validateBuildHistory(
        release.ReleaseTag.parse('android/v1.2.3+24'),
        ['rc/ios/v1.2.3+24'],
        revision: same,
        commits: {'rc/ios/v1.2.3+24': same},
      ),
      throwsA(
        isA<release.ReleaseFailure>().having(
          (error) => error.message,
          'message',
          contains('another channel'),
        ),
      ),
    );
    expect(
      () => release.validateBuildHistory(
        release.ReleaseTag.parse('ios/v1.2.3+24'),
        ['rc/ios/v1.2.3+24'],
        revision: same,
        commits: {'rc/ios/v1.2.3+24': same},
      ),
      throwsA(isA<release.ReleaseFailure>()),
    );
    expect(
      () => release.validateBuildHistory(
        release.ReleaseTag.parse('ios/v1.2.3+25'),
        ['android/v1.2.3+25'],
        revision: same,
        commits: {'android/v1.2.3+25': other},
      ),
      throwsA(isA<release.ReleaseFailure>()),
    );
    expect(
      () => release.validateBuildHistory(
        release.ReleaseTag.parse('ios/v1.2.4+25'),
        ['android/v1.2.3+25'],
        revision: same,
        commits: {'android/v1.2.3+25': same},
      ),
      throwsA(isA<release.ReleaseFailure>()),
    );
  });
  test('Java properties preserve password punctuation and whitespace', () {
    expect(inputs.propertiesValue(' a\\b\n:=\t'), r'\ a\\b\n\:\=\t');
  });
  test(
    'Java properties preserve non-ASCII passwords without encoding loss',
    () {
      expect(inputs.propertiesValue('К'), r'\u041a');
    },
  );
  test(
    'CocoaPods metadata must match the pinned tool, regardless of SwiftPM',
    () {
      expect(
        () => toolchain.validateIosLock(
          'PODS:\n  - Flutter (1.0.0)\nCOCOAPODS: 1.17.0',
        ),
        throwsA(isA<release.ReleaseFailure>()),
      );
    },
  );
  test('SwiftPM project permits a minimal CocoaPods fallback lock', () {
    toolchain.validateIosLock('PODS:\n  - Flutter (1.0.0)\nCOCOAPODS: 1.16.2');
    final pins = [
      {
        'identity': 'firebase-ios-sdk',
        'location': 'https://github.com/firebase/firebase-ios-sdk',
        'state': {'revision': 'a' * 40, 'version': '12.19.0'},
      },
      {
        'identity': 'mapbox-maps-ios',
        'location': 'https://github.com/mapbox/mapbox-maps-ios.git',
        'state': {'revision': 'b' * 40, 'version': '11.29.1'},
      },
    ];
    expect(
      toolchain
          .validateIosSwiftLock(jsonEncode({'version': 2, 'pins': pins}))
          .length,
      2,
    );
    expect(
      () => toolchain.validateIosSwiftLock(
        jsonEncode({'version': 2, 'pins': pins.take(1).toList()}),
      ),
      throwsA(isA<release.ReleaseFailure>()),
    );
    expect(
      () => toolchain.validateIosSwiftLock(
        jsonEncode({
          'version': 2,
          'pins': [...pins, pins.first],
        }),
      ),
      throwsA(isA<release.ReleaseFailure>()),
    );
  });
  test('incomplete or cyclic option syntax is rejected', () {
    expect(
      () => release.options(['--tag']),
      throwsA(isA<release.ReleaseFailure>()),
    );
    expect(
      () => release.options(['--tag', 'a', '--tag', 'b']),
      throwsA(isA<release.ReleaseFailure>()),
    );
  });
  group('strict release tags', () {
    for (final platform in ['android', 'ios']) {
      for (final prefix in ['', 'rc/']) {
        test('$prefix$platform/v1.8.0+108', () {
          final tag = release.ReleaseTag.parse('$prefix$platform/v1.8.0+108');
          expect(tag.version, '1.8.0');
          expect(tag.build, 108);
          expect(tag.production, prefix.isEmpty);
          expect(tag.platform, platform);
        });
      }
    }
    for (final tag in [
      'v1.8.0+108',
      'ios/v1.8+108',
      'ios/v01.8.0+108',
      'ios/v1.8.0+0',
      'ios/v1.8.0+0108',
      'ios/v1.8.0+10000',
      'android/v1.8.0+2100000001',
      'ios/v1.8.0+108\n',
      'rc/ios/v1.8.0+108/extra',
      'rc/android/v1.8.0-rc.1+108',
      'android/v1.8.0+999999999999999999999999999999',
      'android/v10000.0.0+1',
      'android/v1.8.0+108;echo bad',
    ]) {
      test(
        'reject $tag',
        () => expect(
          () => release.ReleaseTag.parse(tag),
          throwsA(isA<release.ReleaseFailure>()),
        ),
      );
    }
    test('store boundaries', () {
      expect(
        release.ReleaseTag.parse('android/v0.0.1+2100000000').build,
        2100000000,
      );
      expect(release.ReleaseTag.parse('ios/v1.0.0+9999').build, 9999);
    });
    test('RC cannot choose production destinations', () {
      expect(
        release.ReleaseTag.parse('rc/android/v1.0.0+1').toJson()['destination'],
        'internal',
      );
      expect(
        release.ReleaseTag.parse('rc/ios/v1.0.0+1').toJson()['destination'],
        'testflight',
      );
    });
  });

  test('production is fail-closed; RC ignores production switch', () {
    final prod = release.ReleaseTag.parse('android/v1.0.0+1');
    for (final value in [null, '', 'false', 'TRUE', '1']) {
      expect(
        () => release.validateProduction(prod, {
          'PRODUCTION_PUBLISHING_ENABLED': ?value,
        }),
        throwsA(isA<release.ReleaseFailure>()),
      );
    }
    release.validateProduction(prod, {'PRODUCTION_PUBLISHING_ENABLED': 'true'});
    release.validateProduction(
      release.ReleaseTag.parse('rc/android/v1.0.0+1'),
      {},
    );
  });

  test('manual/cross-platform provider context is rejected', () {
    for (final platform in ['android', 'ios']) {
      expect(
        () => release.validateEvent(
          release.ReleaseTag.parse('rc/$platform/v1.0.0+1'),
          {},
        ),
        throwsA(isA<release.ReleaseFailure>()),
      );
    }
  });

  test('iOS webhook context enforces repository and excludes PR', () {
    final tag = release.ReleaseTag.parse('rc/ios/v1.0.0+1');
    final env = {
      'CM_BUILD_ID': 'fixture',
      'CM_TAG': tag.tag,
      'CM_REPO_SLUG': 'auyltech/prokat',
      'CM_PULL_REQUEST': 'false',
    };
    release.validateEvent(tag, env);
    expect(
      () => release.validateEvent(tag, {...env, 'CM_PULL_REQUEST': 'true'}),
      throwsA(isA<release.ReleaseFailure>()),
    );
    expect(
      () =>
          release.validateEvent(tag, {...env, 'CM_REPO_SLUG': 'someone/fork'}),
      throwsA(isA<release.ReleaseFailure>()),
    );
  });

  test('iOS production accepts only an exact webhook; RC does not', () {
    final tag = release.ReleaseTag.parse('ios/v1.0.0+1');
    final env = {
      'CM_BUILD_ID': 'fixture',
      'CM_TAG': tag.tag,
      'CM_REPO_SLUG': 'auyltech/prokat',
      'CM_PULL_REQUEST': 'false',
      'CM_TRIGGER_SOURCE': 'webhook',
    };
    release.validateEvent(tag, env);
    for (final source in ['api', 'schedule', '', 'Webhook']) {
      expect(
        () => release.validateEvent(tag, {...env, 'CM_TRIGGER_SOURCE': source}),
        throwsA(
          isA<release.ReleaseFailure>().having(
            (error) => error.toString(),
            'code',
            contains('IOS_PRODUCTION_REQUIRES_WEBHOOK'),
          ),
        ),
      );
    }
    final missing = {...env}..remove('CM_TRIGGER_SOURCE');
    expect(
      () => release.validateEvent(tag, missing),
      throwsA(isA<release.ReleaseFailure>()),
    );
    final rc = release.ReleaseTag.parse('rc/ios/v1.0.0+1');
    release.validateEvent(rc, {
      ...env,
      'CM_TAG': rc.tag,
      'CM_TRIGGER_SOURCE': 'api',
    });
    release.validateEvent(
      rc,
      {...env, 'CM_TAG': rc.tag}..remove('CM_TRIGGER_SOURCE'),
    );
  });

  test('cloud authorization is exact and stays off without every gate', () {
    const commit = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
    final android = release.ReleaseTag.parse('android/v1.2.4+25');
    final ios = release.ReleaseTag.parse('ios/v1.2.4+25');
    final androidEnv = {
      'PRODUCTION_PUBLISHING_ENABLED': 'true',
      'GITHUB_RUN_ATTEMPT': '1',
      'PRODUCTION_RELEASE_AUTH_ANDROID': '${android.tag}@$commit#1',
    };
    release.validateCloudAuthorization(android, androidEnv, commit: commit);
    release.validateCloudAuthorization(android, androidEnv, commit: commit);
    final iosEnv = {
      'PRODUCTION_PUBLISHING_ENABLED': 'true',
      'PRODUCTION_RELEASE_AUTH_IOS': '${ios.tag}@$commit',
    };
    release.validateCloudAuthorization(ios, iosEnv, commit: commit);
    final disabled = [
      {...androidEnv}..remove('PRODUCTION_PUBLISHING_ENABLED'),
      {...androidEnv, 'PRODUCTION_PUBLISHING_ENABLED': ''},
      {...androidEnv, 'PRODUCTION_PUBLISHING_ENABLED': 'false'},
      {...androidEnv, 'PRODUCTION_PUBLISHING_ENABLED': 'TRUE'},
      {...androidEnv, 'PRODUCTION_PUBLISHING_ENABLED': '1'},
    ];
    for (final env in disabled) {
      expect(
        () => release.validateCloudAuthorization(android, env, commit: commit),
        throwsA(isA<release.ReleaseFailure>()),
      );
    }
    for (final bad in [
      {
        ...androidEnv,
        'PRODUCTION_RELEASE_AUTH_ANDROID': '${android.tag}@$commit#2',
      },
      {...androidEnv, 'GITHUB_RUN_ATTEMPT': '2'},
      {...androidEnv, 'GITHUB_RUN_ATTEMPT': 'x'},
      {
        ...androidEnv,
        'PRODUCTION_RELEASE_AUTH_ANDROID': ' ${android.tag}@$commit#1',
      },
      {
        ...androidEnv,
        'PRODUCTION_RELEASE_AUTH_ANDROID': '${android.tag}@${'b' * 40}#1',
      },
      {...iosEnv},
    ]) {
      expect(
        () => release.validateCloudAuthorization(android, bad, commit: commit),
        throwsA(
          isA<release.ReleaseFailure>().having(
            (error) => error.toString(),
            'code',
            contains('ANDROID_CLOUD_AUTHORIZATION_INVALID'),
          ),
        ),
      );
    }
    expect(
      () => release.validateCloudAuthorization(ios, {
        ...iosEnv,
        'PRODUCTION_RELEASE_AUTH_IOS': '${ios.tag}@$commit ',
      }, commit: commit),
      throwsA(
        isA<release.ReleaseFailure>().having(
          (error) => error.toString(),
          'code',
          contains('IOS_CLOUD_AUTHORIZATION_INVALID'),
        ),
      ),
    );
    expect(
      () => release.validateCloudAuthorization(
        release.ReleaseTag.parse('rc/android/v1.2.4+25'),
        androidEnv,
        commit: commit,
      ),
      throwsA(isA<release.ReleaseFailure>()),
    );
  });

  group('metadata and shared notes', () {
    late Directory temp;
    final tag = release.ReleaseTag.parse('rc/ios/v1.8.0+108');
    setUp(() {
      temp = Directory.systemTemp.createTempSync('prokat-release-test-');
      release.writeJson('${temp.path}/releases/1.8.0/release.json', {
        'schema': 1,
        'version': '1.8.0',
        'ready': true,
      });
      for (final language in ['ru', 'en', 'kk']) {
        File('${temp.path}/releases/1.8.0/$language.txt')
            .writeAsStringSync('Update $language\r\nSecond line');
      }
    });
    tearDown(() => temp.deleteSync(recursive: true));
    test('notes generate correct store formats and retain original Kazakh', () {
      release.prepare(tag, 'a' * 40, temp);
      final apple = jsonDecode(
        File('${temp.path}/build/release/apple-localizations.json')
            .readAsStringSync(),
      ) as List;
      expect(apple.map((n) => n['locale']), ['ru', 'en-US', 'en-GB']);
      expect(
        File('${temp.path}/build/release/play/kk/changelogs/108.txt')
            .readAsStringSync(),
        'Update kk\nSecond line',
      );
      expect(File('${temp.path}/releases/1.8.0/kk.txt').existsSync(), isTrue);
      expect(
        File('${temp.path}/build/release/release.env').readAsStringSync(),
        contains('RELEASE_BUILD=108\n'),
      );
    });
    test('missing notes fail', () {
      File('${temp.path}/releases/1.8.0/ru.txt').deleteSync();
      expect(
        () => release.readNotes(temp, tag),
        throwsA(isA<release.ReleaseFailure>()),
      );
    });
    for (final text in [
      '',
      'TODO',
      '<html>',
      'x' * 501,
      '\uFEFFtext',
      'bad\u0000text',
    ]) {
      test('invalid notes fail (${text.length} chars)', () {
        File('${temp.path}/releases/1.8.0/en.txt').writeAsStringSync(text);
        expect(
          () => release.readNotes(temp, tag),
          throwsA(isA<release.ReleaseFailure>()),
        );
      });
    }
    test('unapproved draft fails', () {
      release.writeJson('${temp.path}/releases/1.8.0/release.json', {
        'schema': 1,
        'version': '1.8.0',
        'ready': false,
      });
      expect(
        () => release.readNotes(temp, tag),
        throwsA(isA<release.ReleaseFailure>()),
      );
    });
  });
}
