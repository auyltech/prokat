import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/release/cli.dart';
import '../../tool/release/release.dart';

const sha = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const other = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

class Fixture {
  String version = '1.2.3+19';
  String mainSha = sha;
  bool dirty = false, failRemote = false, failPush = false;
  bool metadataReady = true, omitNotes = false, exportFalse = true;
  bool missingTracking = false, missingObject = false;
  String? trackingSha;
  final calls = <List<String>>[];
  final remote = <String, String>{};
  final local = <String, String>{};
  final writes = <List<String>>[];
  final output = <String>[];
  final reads = <String>[];
  final answers = <String>['y', 'PUBLISH PRODUCTION'];
  final env = <String, String>{};
  final states = <String, Map<String, dynamic>>{};
  String git(List<String> args) {
    calls.add(List<String>.from(args));
    switch (args.first) {
      case 'status':
        return dirty ? ' M pubspec.yaml' : '';
      case 'ls-remote':
        if (failRemote) blocked('Remote unavailable');
        return {
          'refs/heads/main': mainSha,
          ...remote,
        }.entries.map((e) => '${e.value}\t${e.key}').join('\n');
      case 'tag':
        if (args[1] == '--list') return local.keys.join('\n');
        writes.add(args);
        local[args[2]] = args[3];
        return '';
      case 'rev-parse':
        if (args.last.startsWith('refs/remotes/')) {
          if (missingTracking) blocked('missing tracking ref');
          return trackingSha ?? mainSha;
        }
        return local[args.last.substring(10).replaceAll('^{commit}', '')]!;
      case 'cat-file':
        if (missingObject) blocked('missing object');
        return '';
      case 'fetch':
        writes.add(args);
        return '';
      case 'push':
        writes.add(args);
        if (failPush) blocked('Push failed');
        return '';
      default:
        throw StateError('Unexpected git $args');
    }
  }

  String blob(String commit, String path) {
    expect(commit, sha);
    reads.add(path);
    if (path == 'pubspec.yaml') return 'name: prokat\nversion: $version\n';
    if (path.endsWith('release.json')) {
      return jsonEncode({
        'schema': 1,
        'version': version.split('+').first,
        'ready': metadataReady,
      });
    }
    if (path.endsWith('.txt')) {
      if (omitNotes) blocked('Missing required translation');
      return 'Improvements';
    }
    if (path.endsWith('production.json')) {
      return jsonEncode({
        'APP_ENV': 'production',
        'API_BASE_URL': 'https://api.prokat.auyltech.kz',
        'ENABLE_FIREBASE_SERVICES': 'true',
      });
    }
    if (path.endsWith('Info.plist')) {
      return '<key>ITSAppUsesNonExemptEncryption</key><${exportFalse ? 'false' : 'true'}/>';
    }
    return 'release.dart ci PRODUCTION_PUBLISHING_ENABLED verify_android.dart '
        'verify_ios.py play.rb preflight ios_store.py preflight validateProduction';
  }

  ReleaseCli get cli => ReleaseCli(
    runGit: git,
    readBlob: blob,
    environment: env,
    confirm: (_) => answers.removeAt(0),
    printLine: output.add,
    storeStates: states,
  );
  void pair(String name, {String commit = sha}) {
    remote['refs/tags/$name'] = other; // Annotated object != commit.
    remote['refs/tags/$name^{}'] = commit;
  }
}

void main() {
  final failure = throwsA(isA<ReleaseFailure>());
  test(
    'shared CI history validates both platforms and exact paired commit',
    () {
      for (final platform in ['android', 'ios']) {
        final otherPlatform = platform == 'android' ? 'ios' : 'android';
        final tag = ReleaseTag.parse('rc/$platform/v1.2.3+19');
        final pair = 'rc/$otherPlatform/v1.2.3+19';
        validateBuildHistory(tag, [pair], revision: sha, commits: {pair: sha});
        for (final commits in [
          <String, String>{},
          {pair: other},
        ]) {
          expect(
            () => validateBuildHistory(
              tag,
              [pair],
              revision: sha,
              commits: commits,
            ),
            failure,
          );
        }
        expect(
          () => validateBuildHistory(tag, ['rc/$otherPlatform/v1.2.4+19']),
          failure,
        );
        expect(
          () => validateBuildHistory(tag, ['rc/$otherPlatform/v1.2.3+20']),
          failure,
        );
        validatePubspecVersion(tag, 'version: 1.2.3+19\n');
        expect(
          () => validatePubspecVersion(tag, 'version: 1.2.3+20\n'),
          failure,
        );
      }
    },
  );
  for (final platform in ['android', 'ios']) {
    for (final channel in ['rc', 'production']) {
      test(
        '$platform $channel: preview/dry-run and exact annotated tag push',
        () {
          final f = Fixture()..env['PRODUCTION_PUBLISHING_ENABLED'] = 'true';
          final cli = f.cli;
          final dry = cli.plan(platform, channel, dryRun: true);
          expect(
            dry.release.tag,
            '${channel == 'rc' ? 'rc/' : ''}$platform/v1.2.3+19',
          );
          cli.execute(dry, dryRun: true);
          expect(f.writes, isEmpty);
          final real = cli.plan(platform, channel, dryRun: false);
          cli.execute(real, dryRun: false);
          expect(f.writes.map((a) => a.first), ['fetch', 'tag', 'push']);
          expect(f.writes[1].take(4), ['tag', '-a', real.release.tag, sha]);
          expect(f.writes.last, [
            'push',
            'origin',
            'refs/tags/${real.release.tag}:refs/tags/${real.release.tag}',
          ]);
        },
      );
    }
    test('$platform production real plan is default deny before git', () {
      final f = Fixture();
      expect(() => f.cli.plan(platform, 'production', dryRun: false), failure);
      expect(f.writes, isEmpty);
      expect(f.calls, isEmpty);
      expect(f.reads, isEmpty);
    });
  }
  test(
    'version comes only from immutable remote main blob, never local pubspec',
    () {
      final f = Fixture()..version = '1.2.3+20';
      expect(f.cli.plan('ios', 'rc', dryRun: false).release.build, 20);
      expect(f.reads, contains('pubspec.yaml'));
      expect(pubspecVersion('version: 1.2.4+21 # common\n'), '1.2.4+21');
      for (final invalid in [
        'version: 1.2.3',
        'version: 1.2.3+19\nversion: 1.2.3+20',
        'version: 1.2.3+10000',
      ]) {
        expect(() => pubspecVersion(invalid), failure);
      }
    },
  );
  for (final reason in ['dirty', 'remote', 'metadata', 'notes', 'export']) {
    test('$reason blocks before writes', () {
      final f = Fixture();
      switch (reason) {
        case 'dirty':
          f.dirty = true;
        case 'remote':
          f.failRemote = true;
        case 'metadata':
          f.metadataReady = false;
        case 'notes':
          f.omitNotes = true;
        case 'export':
          f.exportFalse = false;
      }
      expect(() => f.cli.plan('ios', 'rc', dryRun: false), failure);
      expect(f.writes, isEmpty);
    });
  }
  test('missing main and malformed refs fail closed', () {
    final f = Fixture();
    final cli = ReleaseCli(
      runGit: (a) => a.first == 'ls-remote' ? '' : f.git(a),
      readBlob: f.blob,
      environment: {},
      confirm: (_) => 'y',
      printLine: (_) {},
    );
    expect(() => cli.plan('ios', 'rc', dryRun: false), failure);
    expect(() => remoteRefs('bad refs/heads/main'), failure);
  });
  for (final answer in ['', 'N', 'yes']) {
    test('cancel $answer: no fetch, files, refs, tag or push', () {
      final f = Fixture()..answers[0] = answer;
      f.cli.execute(f.cli.plan('android', 'rc', dryRun: false), dryRun: false);
      expect(f.writes, isEmpty);
      expect(f.local, isEmpty);
    });
  }
  test('production second confirmation required', () {
    final f = Fixture()
      ..env['PRODUCTION_PUBLISHING_ENABLED'] = 'true'
      ..answers[1] = 'no';
    f.cli.execute(
      f.cli.plan('ios', 'production', dryRun: false),
      dryRun: false,
    );
    expect(f.writes, isEmpty);
  });
  test('main advanced after preview: stop before tag', () {
    final f = Fixture();
    final plan = f.cli.plan('android', 'rc', dryRun: false);
    f.mainSha = other;
    expect(() => f.cli.execute(plan, dryRun: false), failure);
    expect(f.writes, isEmpty);
  });
  test('main changes during metadata inspection: no stale dry-run plan', () {
    final f = Fixture();
    final cli = ReleaseCli(
      runGit: f.git,
      readBlob: (commit, path) {
        final value = f.blob(commit, path);
        if (path.endsWith('production.json')) f.mainSha = other;
        return value;
      },
      environment: {},
      confirm: (_) => 'y',
      printLine: (_) {},
    );
    expect(() => cli.plan('android', 'rc', dryRun: false), failure);
    expect(f.writes, isEmpty);
  });
  test('remote disappears after confirmation: fail closed without tag', () {
    final f = Fixture();
    final plan = f.cli.plan('ios', 'rc', dryRun: false);
    f.failRemote = true;
    expect(() => f.cli.execute(plan, dryRun: false), failure);
    expect(f.writes, isEmpty);
  });
  test('main changes during final fetch: stop without tag', () {
    final f = Fixture();
    final cli = ReleaseCli(
      runGit: (args) {
        final result = f.git(args);
        if (args.first == 'fetch') f.mainSha = other;
        return result;
      },
      readBlob: f.blob,
      environment: {},
      confirm: (_) => 'y',
      printLine: (_) {},
    );
    final plan = cli.plan('android', 'rc', dryRun: false);
    expect(() => cli.execute(plan, dryRun: false), failure);
    expect(f.writes.map((a) => a.first), ['fetch']);
    expect(f.local, isEmpty);
  });
  for (final local in [true, false]) {
    test('existing ${local ? 'local' : 'remote'} target immutable', () {
      final f = Fixture();
      if (local) {
        f.local['rc/ios/v1.2.3+19'] = sha;
      } else {
        f.pair('rc/ios/v1.2.3+19');
      }
      expect(() => f.cli.plan('ios', 'rc', dryRun: false), failure);
      expect(f.writes, isEmpty);
    });
  }
  test('target appeared during confirmation: stop', () {
    final f = Fixture();
    final plan = f.cli.plan('ios', 'rc', dryRun: false);
    f.pair(plan.release.tag);
    expect(() => f.cli.execute(plan, dryRun: false), failure);
    expect(f.writes, isEmpty);
  });
  test(
    'annotated paired platform same SHA allowed, different SHA rejected',
    () {
      final f = Fixture()..pair('rc/android/v1.2.3+19');
      f.cli.plan('ios', 'rc', dryRun: false);
      f.pair('rc/android/v1.2.3+19', commit: other);
      expect(() => f.cli.plan('ios', 'rc', dryRun: false), failure);
    },
  );
  test(
    'both channels block same-platform same build (promotion unsupported)',
    () {
      final f = Fixture()
        ..pair('rc/android/v1.2.3+19')
        ..env['PRODUCTION_PUBLISHING_ENABLED'] = 'true';
      expect(() => f.cli.plan('android', 'production', dryRun: false), failure);
    },
  );
  test('iOS-only retry then next common release monotonically increase', () {
    final f = Fixture()
      ..pair('rc/android/v1.2.3+19')
      ..pair('rc/ios/v1.2.3+19')
      ..version = '1.2.3+20';
    f.cli.plan('ios', 'rc', dryRun: false);
    f.pair('rc/ios/v1.2.3+20');
    f.version = '1.2.4+20';
    expect(() => f.cli.plan('android', 'rc', dryRun: false), failure);
    f.version = '1.2.4+21';
    f.cli.plan('android', 'rc', dryRun: false);
    f.cli.plan('ios', 'rc', dryRun: false);
  });
  test('known accepted binary and other-store higher history block upload', () {
    final f = Fixture()
      ..states['android'] = {
        'package': 'com.auyltech.prokat',
        'historical_floor': 18,
        'codes': [19],
      };
    expect(() => f.cli.plan('android', 'rc', dryRun: false), failure);
    expect(
      () => f.cli.plan('ios', 'rc', dryRun: false),
      failure,
    ); // No paired provenance.
    f.pair('rc/android/v1.2.3+19');
    f.cli.plan('ios', 'rc', dryRun: false);
    f.states['android']!['codes'] = [20];
    expect(() => f.cli.plan('ios', 'rc', dryRun: false), failure);
  });
  test('failed push retains local tag and gives non-force recovery', () {
    final f = Fixture()..failPush = true;
    expect(
      () =>
          f.cli.execute(f.cli.plan('ios', 'rc', dryRun: false), dryRun: false),
      throwsA(
        isA<ReleaseFailure>().having(
          (e) => e.message,
          'recovery',
          contains('Tag retained locally'),
        ),
      ),
    );
    expect(f.local['rc/ios/v1.2.3+19'], sha);
    expect(
      f.writes.any((a) => a.contains('--force') || a.contains('-d')),
      isFalse,
    );
    expect(() => f.cli.plan('ios', 'rc', dryRun: false), failure);
  });
  test('cached Apple accepted/upload build blocks same build and permits higher retry', () {
    final f = Fixture()
      ..states['ios'] = {
        'app_id': '6817078475',
        'historical_floor': 17,
        'builds': [
          {
            'attributes': {'version': '19'},
          },
        ],
        'uploads': [
          {
            'attributes': {'cfBundleVersion': '20'},
          },
        ],
      };
    expect(() => f.cli.plan('ios', 'rc', dryRun: false), failure);
    f.version = '1.2.3+20';
    expect(() => f.cli.plan('ios', 'rc', dryRun: false), failure);
    f.version = '1.2.3+21';
    f.cli.plan('ios', 'rc', dryRun: false);
    f.states['ios']!['app_id'] = 'other';
    expect(() => f.cli.plan('ios', 'rc', dryRun: false), failure);
  });
  test(
    'real immutable Git blobs override a different committed local pubspec',
    () {
      final repo = Directory.systemTemp.createTempSync('prokat-cli-blob-test-');
      addTearDown(() => repo.deleteSync(recursive: true));
      String run(List<String> args) => git(args, directory: repo.path);
      run(['init', '--initial-branch=main']);
      run(['config', 'user.name', 'Release Test']);
      run(['config', 'user.email', 'release@example.invalid']);
      final f = Fixture();
      for (final path in [
        'pubspec.yaml',
        'tool/release/cli.dart',
        'tool/release/production.json',
        '.github/workflows/android-release.yml',
        'releases/1.2.3/release.json',
        for (final language in ['ru', 'en', 'kk'])
          'releases/1.2.3/$language.txt',
      ]) {
        final file = File('${repo.path}/$path');
        file.parent.createSync(recursive: true);
        file.writeAsStringSync(f.blob(sha, path));
      }
      run(['add', '.']);
      run(['commit', '-m', 'Approved fixture main']);
      final approved = run(['rev-parse', 'HEAD']);
      run(['switch', '-c', 'feature']);
      File('${repo.path}/pubspec.yaml')
          .writeAsStringSync('version: 9.9.9+99\n');
      run(['commit', '-am', 'Different local fixture version']);
      run(['update-ref', 'refs/remotes/origin/main', approved]);
      final before = run(['show-ref']);
      final cli = ReleaseCli(
        runGit: (args) => args.first == 'ls-remote'
            ? '$approved\trefs/heads/main'
            : run(args),
        readBlob: (commit, path) => readGitBlob(repo.path, commit, path),
        environment: {},
        confirm: (_) => 'n',
        printLine: (_) {},
      );
      final dry = cli.plan('android', 'rc', dryRun: true);
      expect(dry.release.build, 19);
      expect(dry.sha, approved);
      cli.execute(dry, dryRun: true);
      final real = cli.plan('android', 'rc', dryRun: false);
      cli.execute(real, dryRun: false);
      expect(run(['show-ref']), before);
      expect(run(['status', '--porcelain']), isEmpty);
    },
  );
  test('production dry-run ignores the gate and never confirms or writes', () {
    for (final enabled in [false, true]) {
      final f = Fixture();
      if (enabled) f.env['PRODUCTION_PUBLISHING_ENABLED'] = 'true';
      final plan = f.cli.plan('android', 'production', dryRun: true);
      expect(plan.dryRun, isTrue);
      f.cli.execute(plan, dryRun: true);
      expect(f.writes, isEmpty);
      expect(f.answers, ['y', 'PUBLISH PRODUCTION']);
      final text = f.output.join('\n');
      expect(text, contains(enabled ? 'ENABLED' : 'DISABLED'));
      expect(
        text,
        contains('DRY RUN: no files, refs, tags or uploads changed.'),
      );
      expect(
        f.calls.where(
          (args) =>
              args.first == 'fetch' ||
              args.first == 'push' ||
              (args.first == 'tag' && args[1] != '--list'),
        ),
        isEmpty,
      );
    }
  });
  for (final value in <String?>[null, 'false', 'TRUE', ' true', '']) {
    test(
      'real production plan blocks on gate ${value ?? 'absent'} before git',
      () {
        final f = Fixture();
        if (value != null) f.env['PRODUCTION_PUBLISHING_ENABLED'] = value;
        expect(() => f.cli.plan('ios', 'production', dryRun: false), failure);
        expect(f.calls, isEmpty);
        expect(f.reads, isEmpty);
        expect(f.answers, ['y', 'PUBLISH PRODUCTION']);
      },
    );
  }
  test('dry-run plan cannot be executed', () {
    final f = Fixture();
    final plan = f.cli.plan('android', 'rc', dryRun: true);
    expect(() => f.cli.execute(plan, dryRun: false), failure);
    expect(f.writes, isEmpty);
    expect(f.answers, ['y', 'PUBLISH PRODUCTION']);
  });
  test('missing origin/main blocks dry-run before blobs', () {
    final f = Fixture()..missingTracking = true;
    expect(() => f.cli.plan('ios', 'rc', dryRun: true), failure);
    expect(f.reads, isEmpty);
    expect(f.writes, isEmpty);
  });
  test('stale origin/main blocks dry-run before blobs', () {
    final f = Fixture()..trackingSha = other;
    expect(
      () => f.cli.plan('android', 'production', dryRun: true),
      throwsA(
        isA<ReleaseFailure>().having(
          (error) => error.message,
          'message',
          contains('stale'),
        ),
      ),
    );
    expect(f.reads, isEmpty);
    expect(f.calls.any((args) => args.first == 'fetch'), isFalse);
  });
  test('missing commit object blocks dry-run without fetch', () {
    final f = Fixture()..missingObject = true;
    expect(() => f.cli.plan('ios', 'rc', dryRun: true), failure);
    expect(f.reads, isEmpty);
    expect(f.calls.any((args) => args.first == 'fetch'), isFalse);
  });
  test('rc and production never share a build number', () {
    final f = Fixture()
      ..version = '1.2.3+24'
      ..pair('rc/ios/v1.2.3+24');
    expect(
      () => f.cli.plan('android', 'production', dryRun: true),
      throwsA(
        isA<ReleaseFailure>().having(
          (error) => error.message,
          'message',
          contains('another channel'),
        ),
      ),
    );
    expect(() => f.cli.plan('ios', 'production', dryRun: true), failure);
    f.cli.plan('android', 'rc', dryRun: true);
    final paired = Fixture()
      ..version = '1.2.3+25'
      ..pair('android/v1.2.3+25')
      ..pair('ios/v1.2.3+25', commit: other);
    expect(() => paired.cli.plan('ios', 'production', dryRun: true), failure);
    final same = Fixture()
      ..version = '1.2.3+25'
      ..pair('android/v1.2.3+25');
    same.cli.plan('ios', 'production', dryRun: true);
  });
  test('store floor cannot be paired through the other channel', () {
    ReleaseCli cliFor(Map<String, String> refs) {
      final f = Fixture()
        ..states['android'] = {
          'package': 'com.auyltech.prokat',
          'historical_floor': 18,
          'codes': [25],
        };
      return f.cli;
    }

    final rcRefs = {
      'refs/tags/rc/android/v1.2.3+25': other,
      'refs/tags/rc/android/v1.2.3+25^{}': sha,
    };
    expect(
      () =>
          cliFor(rcRefs)
              .validateStores(ReleaseTag.parse('ios/v1.2.3+25'), sha, rcRefs),
      failure,
    );
    final prodRefs = {
      'refs/tags/android/v1.2.3+25': other,
      'refs/tags/android/v1.2.3+25^{}': sha,
    };
    cliFor(prodRefs)
        .validateStores(ReleaseTag.parse('ios/v1.2.3+25'), sha, prodRefs);
  });
  test('stale tracking ref does not read old blobs from a real repository', () {
    final repo = Directory.systemTemp.createTempSync('prokat-cli-stale-');
    addTearDown(() => repo.deleteSync(recursive: true));
    String run(List<String> args) => git(args, directory: repo.path);
    run(['init', '--initial-branch=main']);
    run(['config', 'user.name', 'Release Test']);
    run(['config', 'user.email', 'release@example.invalid']);
    File('${repo.path}/pubspec.yaml').writeAsStringSync('version: 1.0.0+1\n');
    run(['add', '.']);
    run(['commit', '-m', 'old']);
    final old = run(['rev-parse', 'HEAD']);
    run(['update-ref', 'refs/remotes/origin/main', old]);
    final reads = <String>[];
    final cli = ReleaseCli(
      runGit: (args) =>
          args.first == 'ls-remote' ? '$sha\trefs/heads/main' : run(args),
      readBlob: (commit, path) {
        reads.add('$commit:$path');
        return 'version: 9.9.9+99\n';
      },
      environment: {},
      confirm: (_) => 'y',
      printLine: (_) {},
    );
    expect(() => cli.plan('android', 'rc', dryRun: true), failure);
    expect(reads, isEmpty);
    expect(run(['rev-parse', 'refs/remotes/origin/main']), old);
  });
  test('byte reader rejects BOM rather than silently stripping it', () {
    expect(() => releaseText([239, 187, 191, 65]), failure);
    expect(releaseText(utf8.encode('Қазақша')), 'Қазақша');
  });
  test('PowerShell wrappers forward platform/channel and DryRun exactly', () {
    if (!Platform.isWindows) return;
    final result = Process.runSync('powershell', [
      '-NoProfile',
      '-Command',
      ". ./tool/release/prokat-release.ps1; "
          "function Invoke-ProkatRelease { param(\$Platform,\$Channel,[switch]\$DryRun) "
          "Write-Output (\$Platform + ':' + \$Channel + ':' + \$DryRun) }; "
          "prokat-rc-android -DryRun; prokat-rc-ios -DryRun; "
          "prokat-prod-android -DryRun; prokat-prod-ios -DryRun",
    ]);
    expect(result.exitCode, 0);
    expect((result.stdout as String).trim().split(RegExp(r'\r?\n')), [
      'android:rc:True',
      'ios:rc:True',
      'android:production:True',
      'ios:production:True',
    ]);
  });
  test('documented wrappers and owner commands stay aligned', () {
    final script = File('tool/release/prokat-release.ps1').readAsStringSync();
    final readme = File('CICD-README.md').readAsStringSync();
    for (final name in [
      'prokat-rc-android',
      'prokat-rc-ios',
      'prokat-prod-android',
      'prokat-prod-ios',
    ]) {
      expect(script, contains('function $name '));
      expect(readme, contains(name));
    }
    expect(script, contains("\$cliArgs += '--dry-run'"));
    expect(readme, isNot(contains('git tag -a')));
    expect(readme, contains('1.2.3+23'));
    expect(readme, contains('1.2.4+24'));
  });
  test('PowerShell rejects alias/function collisions and mistyped dry-run', () {
    if (!Platform.isWindows) return;
    for (final setup in [
      'Set-Alias prokat-rc-ios Write-Output',
      'function prokat-rc-ios { Write-Output existing }',
      'function Invoke-ProkatRelease { Write-Output existing }',
    ]) {
      final result = Process.runSync('powershell', [
        '-NoProfile',
        '-Command',
        "$setup; try { . ./tool/release/prokat-release.ps1; exit 9 } catch { 'COLLISION BLOCKED' }",
      ]);
      expect(result.exitCode, 0);
      expect(result.stdout, contains('COLLISION BLOCKED'));
    }
    final result = Process.runSync('powershell', [
      '-NoProfile',
      '-Command',
      ". ./tool/release/prokat-release.ps1; . ./tool/release/prokat-release.ps1; "
          "function Invoke-ProkatRelease { throw 'MUST NOT RUN' }; "
          "try { prokat-rc-ios -DryRunn; exit 9 } catch { "
          "if (\$_ -match 'MUST NOT RUN') { exit 8 }; 'TYPO BLOCKED' }",
    ]);
    expect(result.exitCode, 0);
    expect(result.stdout, contains('TYPO BLOCKED'));
  });
  test('production CLI blocks on the gate before git exists', () {
    final dart = _sdkDart();
    final result = Process.runSync(
      dart,
      [File('tool/release/cli.dart').absolute.path, 'android', 'production'],
      workingDirectory: Directory.systemTemp.path,
      includeParentEnvironment: false,
      environment: _gitlessEnvironment(dart),
    );
    final output = '${result.stdout}\n${result.stderr}';
    expect(result.exitCode, 1, reason: output);
    expect(output, contains('Production publishing is disabled'));
    expect(output, isNot(contains('Git ')));
    expect(output, isNot(contains('git.exe')));
    expect(output, isNot(contains('ProcessException')));
  });
  test('PowerShell production commands block on the gate without git', () {
    if (!Platform.isWindows) return;
    final dart = _sdkDart();
    final powershell =
        '${Platform.environment['SystemRoot']}\\System32\\WindowsPowerShell\\v1.0\\powershell.exe';
    for (final command in ['prokat-prod-android', 'prokat-prod-ios']) {
      final result = Process.runSync(
        powershell,
        [
          '-NoProfile',
          '-Command',
          ". ./tool/release/prokat-release.ps1; $command",
        ],
        workingDirectory: Directory.current.path,
        includeParentEnvironment: false,
        environment: _gitlessEnvironment(dart),
      );
      final output = '${result.stdout}\n${result.stderr}';
      expect(output, contains('PROKAT release blocked'), reason: output);
      expect(
        output,
        contains('Production publishing is disabled'),
        reason: output,
      );
      expect(output, isNot(contains('Git ')));
      expect(output, isNot(contains('git.exe')));
      expect(output, isNot(contains('is not recognized')));
    }
  });
}

String _sdkDart() {
  final resolved = Platform.resolvedExecutable;
  final name = resolved.replaceAll('\\', '/').toLowerCase();
  if (name.endsWith('/dart.exe') || name.endsWith('/dart')) {
    return resolved;
  }
  final cache = Directory(resolved).parent.parent.parent.parent;
  final dart = File('${cache.path}/dart-sdk/bin/dart.exe');
  if (dart.existsSync()) return dart.path;
  final unix = File('${cache.path}/dart-sdk/bin/dart');
  if (unix.existsSync()) return unix.path;
  throw StateError('Cannot locate the Dart SDK next to $resolved');
}

Map<String, String> _gitlessEnvironment(String dart) {
  final root = Platform.environment['SystemRoot'] ?? r'C:\Windows';
  return {
    'PATH': '${File(dart).parent.path};$root\\System32',
    'SYSTEMROOT': root,
    'WINDIR': root,
    'PATHEXT': '.COM;.EXE;.BAT;.CMD',
    'TEMP': Platform.environment['TEMP'] ?? Directory.systemTemp.path,
    'TMP': Platform.environment['TMP'] ?? Directory.systemTemp.path,
  };
}
