import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/updates/app_update_policy.dart';

void main() {
  const forceCases =
      <(String, String?, String?, List<String>, String?, AppUpdatePolicy)>[
        ('1.2.4+19', '19', '1.2.5', ['1.2.4'], null, AppUpdatePolicy.hard),
        ('1.2.4+999', '999', '1.3.0', ['1.2.4'], null, AppUpdatePolicy.hard),
        ('1.2.5', null, '1.2.6', ['1.2.4'], null, AppUpdatePolicy.silent),
        ('1.3.0', '27', '1.3.1', ['1.3.0+27'], null, AppUpdatePolicy.hard),
        ('1.3.0', '28', '1.3.1', ['1.3.0+27'], null, AppUpdatePolicy.silent),
        ('1.3.0', '26', '1.3.1', ['1.3.0+27'], null, AppUpdatePolicy.silent),
        ('1.3.0+27', '28', '1.3.1', ['1.3.0+27'], null, AppUpdatePolicy.silent),
        ('1.3.0+27', null, '1.3.1', ['1.3.0+27'], null, AppUpdatePolicy.silent),
        ('1.3.0', '27.1', '1.3.1', ['1.3.0+27.1'], null, AppUpdatePolicy.hard),
        ('1.3.0', '027', '1.3.1', ['1.3.0+27'], null, AppUpdatePolicy.silent),
        ('1.2.4', null, '1.2.4', ['1.2.4'], null, AppUpdatePolicy.upToDate),
        ('1.2.4', null, '1.2.3', ['1.2.4'], null, AppUpdatePolicy.upToDate),
        ('1.2.4', null, null, ['1.2.4'], null, AppUpdatePolicy.upToDate),
        ('1.2.4', null, 'bad', ['1.2.4'], null, AppUpdatePolicy.upToDate),
        (
          '1.3.0+27',
          '27',
          '1.3.0+28',
          ['1.3.0+27'],
          null,
          AppUpdatePolicy.upToDate,
        ),
        ('1.3.0', '27', null, ['1.3.0+27'], null, AppUpdatePolicy.upToDate),
        ('1.2.4', null, '1.2.4', [], '1.2.5', AppUpdatePolicy.upToDate),
        ('1.2.4', null, null, [], '1.2.5', AppUpdatePolicy.upToDate),
        ('1.2.4', null, '1.2.5', [], '1.3.0', AppUpdatePolicy.silent),
        ('1.2.4', null, '1.3.0', [], '1.4.0', AppUpdatePolicy.soft),
        ('1.2.4', null, '1.2.5', [], '1.2.5', AppUpdatePolicy.hard),
        ('1.2.4', null, '1.2.5', ['1.2.4'], '1.2.5', AppUpdatePolicy.hard),
        ('1.2.4', null, '2.0.0', [], null, AppUpdatePolicy.hard),
      ];
  for (final (installed, build, latest, forced, minimum, expected)
      in forceCases) {
    test(
      'force=$forced installed=$installed native build=$build latest=$latest minimum=$minimum: $expected',
      () {
        expect(
          classifyAppUpdate(
            installed: installed,
            installedBuild: build,
            latest: latest,
            minimum: minimum,
            forcedVersions: forced
                .map((rule) => ForcedAppVersion.tryParse(rule)!)
                .toList(),
          ),
          expected,
        );
      },
    );
  }

  for (final latest in ['1.2.5', '1.3.0', '2.0.0']) {
    test(
      'exact forced rule has priority over minimum and normal rule for $latest',
      () {
        final decision = evaluateAppUpdate(
          installed: '1.2.4',
          latest: latest,
          minimum: '1.2.5',
          forcedVersions: [ForcedAppVersion.tryParse('1.2.4')!],
        );
        expect(decision.policy, AppUpdatePolicy.hard);
        expect(decision.reason, AppUpdateReason.forcedVersion);
      },
    );
  }
  test('unusable emergency rules expose diagnostics but cannot invent availability', () {
    final decision = evaluateAppUpdate(
      installed: '1.2.4',
      latest: '1.2.4',
      minimum: '1.2.5',
      forcedVersions: [ForcedAppVersion.tryParse('1.2.4')!],
    );
    expect(decision.policy, AppUpdatePolicy.upToDate);
    expect(decision.diagnostics, [
      AppUpdateDiagnostic.forcedVersionWithoutNewerStore,
      AppUpdateDiagnostic.minimumWithoutSupportedStore,
    ]);
  });
  test(
    'unreachable minimum falls back to normal minor policy with diagnostics',
    () {
      final decision = evaluateAppUpdate(
        installed: '1.2.4',
        latest: '1.3.0',
        minimum: '1.4.0',
      );
      expect(decision.policy, AppUpdatePolicy.soft);
      expect(decision.reason, AppUpdateReason.minor);
      expect(decision.diagnostics, [
        AppUpdateDiagnostic.minimumWithoutSupportedStore,
      ]);
    },
  );
  const cases = <(String, String?, String?, AppUpdatePolicy)>[
    ('1.2.3', '1.2.3', null, AppUpdatePolicy.upToDate),
    ('1.2.3+18', '1.2.3+19', null, AppUpdatePolicy.upToDate),
    ('1.2.3+19', '1.2.3+18', null, AppUpdatePolicy.upToDate),
    ('1.2.2', '1.2.3', null, AppUpdatePolicy.silent),
    ('1.2.3', '1.2.4', null, AppUpdatePolicy.silent),
    ('1.2.9', '1.2.10', null, AppUpdatePolicy.silent),
    ('1.2.2', '1.3.0', null, AppUpdatePolicy.soft),
    ('1.2.9', '1.3.0', null, AppUpdatePolicy.soft),
    ('1.2.9', '1.3.1', null, AppUpdatePolicy.soft),
    ('1.2.9', '1.3.4', null, AppUpdatePolicy.soft),
    ('1.2.2', '2.0.0', null, AppUpdatePolicy.hard),
    ('1.9.9', '2.0.0', null, AppUpdatePolicy.hard),
    ('1.9.9', '2.0.1', null, AppUpdatePolicy.hard),
    ('1.9.9', '2.3.7', null, AppUpdatePolicy.hard),
    ('1.2.3', '1.2.4', '1.2.4', AppUpdatePolicy.hard),
    ('1.2.3', '1.3.0', '1.2.4', AppUpdatePolicy.hard),
    ('1.2.3', '1.2.3', '1.2.4', AppUpdatePolicy.upToDate),
    ('1.2.3', null, '1.2.4', AppUpdatePolicy.upToDate),
    ('1.2.3', 'broken', '1.2.4', AppUpdatePolicy.upToDate),
    ('1.2.4', '1.2.4', '1.2.4', AppUpdatePolicy.upToDate),
    ('1.2.4', '1.2.5', '1.2.4', AppUpdatePolicy.silent),
    ('1.2.4+18', '1.2.4+19', '1.2.4+20', AppUpdatePolicy.upToDate),
    ('1.2.3', '1.2.4', 'bad', AppUpdatePolicy.silent),
    ('1.2.3', '1.2.4', '', AppUpdatePolicy.silent),
    ('1.2.3', '1.2.4', '1.2', AppUpdatePolicy.silent),
    ('1.2.3', '1.1.99', null, AppUpdatePolicy.upToDate),
    ('2.0.0', '1.99.99', null, AppUpdatePolicy.upToDate),
    ('1.2.3', null, null, AppUpdatePolicy.upToDate),
    ('1.2.3', 'bad', null, AppUpdatePolicy.upToDate),
    ('bad', '2.0.0', '2.0.0', AppUpdatePolicy.upToDate),
    ('1.2.3-beta.1+18', '1.2.3+19', null, AppUpdatePolicy.upToDate),
  ];
  for (final (installed, latest, minimum, expected) in cases) {
    test('$installed -> $latest minimum=$minimum is $expected', () {
      expect(
        classifyAppUpdate(
          installed: installed,
          latest: latest,
          minimum: minimum,
        ),
        expected,
      );
    });
  }

  for (final (remote, store, expected) in <(String?, String?, String?)>[
    ('1.4.0', '1.3.0', '1.4.0'),
    ('1.2.0', '1.3.0', '1.3.0'),
    ('1.3.0', '1.3.0', '1.3.0'),
    ('1.3.0', null, '1.3.0'),
    (null, '1.3.0', '1.3.0'),
    (null, null, null),
    ('bad', '1.3.0', '1.3.0'),
    ('1.3.0', 'bad', '1.3.0'),
    ('', '', null),
    ('1.2.10+18', '1.2.9+99', '1.2.10'),
  ]) {
    test('effective minimum remote=$remote store=$store is $expected', () {
      expect(
        effectiveAppMinimum(remote: remote, store: store)?.toString(),
        expected,
      );
    });
  }

  for (final malformed in [
    '',
    'invalid',
    '1',
    '1.2',
    '1.2.3.4',
    '01.2.3',
    '-1.2.3',
    '1.2.3+',
    '1.2.3+..',
    '1.2.3-beta..1',
    '1.2.3-01',
    '1.2.3!',
  ]) {
    test('malformed version "$malformed" is safely ignored', () {
      expect(parseAppVersion(malformed), isNull);
    });
  }
  test('trimmed SemVer normalizes metadata without lexical comparison', () {
    expect(parseAppVersion(' 1.2.10+store.19 ')?.toString(), '1.2.10');
  });
}
