import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/release/release.dart' as release;

void main() {
  group('all release channels use fresh main ancestry in isolated Git fixtures', () {
    late Directory repo;
    late String approved;
    final tags = [
      for (final platform in ['android', 'ios'])
        for (final prefix in ['rc/', ''])
          release.ReleaseTag.parse('$prefix$platform/v1.8.0+108'),
    ];
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
      release.git(['remote', 'add', 'origin', repo.path], directory: repo.path);
    });
    tearDown(() => repo.deleteSync(recursive: true));
    for (final tag in tags) {
      test('${tag.tag}: approved main source is accepted', () {
        release.validateRevision(
          tag,
          approved,
          ci: false,
          directory: repo.path,
        );
      });
      for (final branch in ['feature', 'dev']) {
        test('${tag.tag}: SHA only in $branch is blocked', () {
          release.git(['switch', '-c', branch], directory: repo.path);
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
              tag,
              candidate,
              ci: false,
              directory: repo.path,
            ),
            throwsA(isA<release.ReleaseFailure>()),
          );
        });
      }
      test('${tag.tag}: wrong revision is blocked', () {
        expect(
          () => release.validateRevision(
            tag,
            '0' * 40,
            ci: false,
            directory: repo.path,
          ),
          throwsA(isA<release.ReleaseFailure>()),
        );
      });
      test('${tag.tag}: dirty tracked source is blocked', () {
        File('${repo.path}/source.txt').writeAsStringSync('uncommitted');
        expect(
          () => release.validateRevision(
            tag,
            approved,
            ci: false,
            directory: repo.path,
          ),
          throwsA(isA<release.ReleaseFailure>()),
        );
      });
      for (final failure in ['missing main', 'unavailable remote']) {
        test('${tag.tag}: $failure fails despite a cached main ref', () {
          release.validateRevision(
            tag,
            approved,
            ci: false,
            directory: repo.path,
          );
          if (failure == 'missing main') {
            release.git(['branch', '-m', 'retired-main'], directory: repo.path);
          } else {
            release.git([
              'remote',
              'set-url',
              'origin',
              '${repo.path}/missing.git',
            ], directory: repo.path);
          }
          expect(
            () => release.validateRevision(
              tag,
              approved,
              ci: false,
              directory: repo.path,
            ),
            throwsA(isA<release.ReleaseFailure>()),
          );
        });
      }
      test('${tag.tag}: fresh main replaces a stale cached ref', () {
        release.validateRevision(
          tag,
          approved,
          ci: false,
          directory: repo.path,
        );
        File('${repo.path}/source.txt').writeAsStringSync('advanced main');
        release.git([
          'commit',
          '-am',
          'Advance fixture main',
        ], directory: repo.path);
        final tip = release.git(['rev-parse', 'HEAD'], directory: repo.path);
        expect(
          release.git(['rev-parse', 'origin/main'], directory: repo.path),
          approved,
        );
        release.validateRevision(tag, tip, ci: false, directory: repo.path);
        expect(
          release.git(['rev-parse', 'origin/main'], directory: repo.path),
          tip,
        );
        release.git(['switch', '--detach', approved], directory: repo.path);
        release.validateRevision(
          tag,
          approved,
          ci: false,
          directory: repo.path,
        );
      });
      for (final annotated in [false, true]) {
        test(
          '${tag.tag}: CI verifies ${annotated ? 'annotated' : 'lightweight'} tag commit',
          () {
            // Temporary fixture tags only; no refs in the application repository.
            release.git(
              annotated
                  ? ['tag', '-a', tag.tag, approved, '-m', 'Fixture tag']
                  : ['tag', tag.tag, approved],
              directory: repo.path,
            );
            release.validateRevision(
              tag,
              approved,
              ci: true,
              directory: repo.path,
            );
            File('${repo.path}/source.txt')
                .writeAsStringSync('other main commit');
            release.git([
              'commit',
              '-am',
              'Other fixture main commit',
            ], directory: repo.path);
            final other = release.git([
              'rev-parse',
              'HEAD',
            ], directory: repo.path);
            expect(
              () => release.validateRevision(
                tag,
                other,
                ci: true,
                directory: repo.path,
              ),
              throwsA(isA<release.ReleaseFailure>()),
            );
          },
        );
      }
      test('${tag.tag}: shallow checkout gets complete history', () {
        File('${repo.path}/source.txt').writeAsStringSync('new main tip');
        release.git([
          'commit',
          '-am',
          'Advance fixture main',
        ], directory: repo.path);
        final shallow = Directory.systemTemp.createTempSync(
          'prokat-shallow-test-',
        );
        addTearDown(() => shallow.deleteSync(recursive: true));
        release.git([
          'clone',
          '--depth=1',
          repo.uri.toString(),
          '${shallow.path}/clone',
        ], directory: repo.path);
        final clone = '${shallow.path}/clone';
        expect(
          release.git([
            'rev-parse',
            '--is-shallow-repository',
          ], directory: clone),
          'true',
        );
        final tip = release.git(['rev-parse', 'HEAD'], directory: clone);
        release.validateRevision(tag, tip, ci: false, directory: clone);
        expect(
          release.git([
            'rev-parse',
            '--is-shallow-repository',
          ], directory: clone),
          'false',
        );
        release.git(['switch', '--detach', approved], directory: clone);
        release.validateRevision(tag, approved, ci: false, directory: clone);
      });
    }
  });
}
