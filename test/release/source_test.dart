import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/release/release.dart' as release;

void main() {
  group(
    'production source ancestry in isolated local Git fixtures (no tags)',
    () {
      late Directory repo;
      late String approved;
      final prod = release.ReleaseTag.parse('android/v1.8.0+108');
      setUp(() {
        repo = Directory.systemTemp.createTempSync('prokat-source-test-');
        release.git(['init', '--initial-branch=main'], directory: repo.path);
        release.git([
          'config',
          'user.name',
          'Release Test',
        ], directory: repo.path);
        release.git([
          'config',
          'user.email',
          'release-test@example.invalid',
        ], directory: repo.path);
        File('${repo.path}/source.txt').writeAsStringSync('approved');
        release.git(['add', 'source.txt'], directory: repo.path);
        release.git(['commit', '-m', 'Fixture source'], directory: repo.path);
        approved = release.git(['rev-parse', 'HEAD'], directory: repo.path);
        // A local self-remote provides a main ref without any network or push.
        release.git([
          'remote',
          'add',
          'origin',
          repo.path,
        ], directory: repo.path);
      });
      tearDown(() => repo.deleteSync(recursive: true));
      test('approved main source is accepted', () {
        release.validateRevision(
          prod,
          approved,
          ci: false,
          directory: repo.path,
        );
      });
      test('unmerged candidate is blocked', () {
        release.git(['switch', '-c', 'candidate'], directory: repo.path);
        File('${repo.path}/source.txt').writeAsStringSync('candidate');
        release.git([
          'commit',
          '-am',
          'Fixture candidate',
        ], directory: repo.path);
        final candidate = release.git([
          'rev-parse',
          'HEAD',
        ], directory: repo.path);
        expect(
          () => release.validateRevision(
            prod,
            candidate,
            ci: false,
            directory: repo.path,
          ),
          throwsA(isA<release.ReleaseFailure>()),
        );
      });
      test('wrong revision is blocked', () {
        expect(
          () => release.validateRevision(
            prod,
            '0' * 40,
            ci: false,
            directory: repo.path,
          ),
          throwsA(isA<release.ReleaseFailure>()),
        );
      });
      test('dirty tracked source is blocked', () {
        File('${repo.path}/source.txt').writeAsStringSync('uncommitted');
        expect(
          () => release.validateRevision(
            prod,
            approved,
            ci: false,
            directory: repo.path,
          ),
          throwsA(isA<release.ReleaseFailure>()),
        );
      });
    },
  );
}
