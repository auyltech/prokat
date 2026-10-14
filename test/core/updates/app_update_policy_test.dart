import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/updates/app_update_policy.dart';

void main() {
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
    ('1.2.3', '1.2.3', '1.2.4', AppUpdatePolicy.hard),
    ('1.2.3', null, '1.2.4', AppUpdatePolicy.hard),
    ('1.2.3', 'broken', '1.2.4', AppUpdatePolicy.hard),
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
