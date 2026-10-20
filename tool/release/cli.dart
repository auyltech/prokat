import 'dart:convert';
import 'dart:io';

import 'release.dart';

typedef GitRunner = String Function(List<String> args);
typedef BlobReader = String Function(String sha, String path);

/// All remote refs, including peeled annotated tags, come from one snapshot.
Map<String, String> remoteRefs(String text) {
  final refs = <String, String>{};
  for (final line in text.split('\n').where((line) => line.trim().isNotEmpty)) {
    final parts = line.trim().split(RegExp(r'\s+'));
    if (parts.length != 2 ||
        !RegExp(r'^[0-9a-f]{40}$').hasMatch(parts.first) ||
        refs.containsKey(parts.last)) {
      blocked('Invalid/ambiguous remote refs; state UNKNOWN');
    }
    refs[parts.last] = parts.first;
  }
  return refs;
}

Map<String, String> releaseCommits(Map<String, String> refs) => {
  for (final entry in refs.entries)
    if (entry.key.startsWith('refs/tags/') && !entry.key.endsWith('^{}'))
      entry.key.substring(10): refs['${entry.key}^{}'] ?? entry.value,
};

class ReleasePlan {
  ReleasePlan(this.release, this.sha, this.refs);
  final ReleaseTag release;
  final String sha;
  final Map<String, String> refs;
  String get channel => release.platform == 'android'
      ? (release.production ? 'Google Play Production' : 'Internal Testing')
      : (release.production
            ? 'App Store Review'
            : 'TestFlight Internal Testing');
  String get preview =>
      'PROKAT Release\n\n'
      'Platform: ${release.platform == 'android' ? 'Android' : 'iOS'}\n'
      'Channel: $channel\n'
      'Version: ${release.version}+${release.build}\n'
      'Commit: $sha\nTag: ${release.tag}\n';
}

class ReleaseCli {
  ReleaseCli({
    required this.runGit,
    required this.readBlob,
    required this.environment,
    required this.confirm,
    required this.printLine,
    this.storeStates = const {},
  });
  final GitRunner runGit;
  final BlobReader readBlob;
  final Map<String, String> environment;
  final String? Function(String prompt) confirm;
  final void Function(String line) printLine;
  final Map<String, Map<String, dynamic>> storeStates;

  Map<String, String> snapshot() =>
      remoteRefs(runGit(['ls-remote', '--heads', '--tags', 'origin']));

  void clean() {
    if (runGit(['status', '--porcelain=v1', '--untracked-files=all'])
        .isNotEmpty) {
      blocked('Working tree/index must be clean, including untracked files');
    }
  }

  ReleasePlan plan(String platform, String channel) {
    if (!{'android', 'ios'}.contains(platform) ||
        !{'rc', 'production'}.contains(channel)) {
      blocked('Unknown command');
    }
    clean();
    final refs = snapshot();
    final sha =
        refs['refs/heads/main'] ?? blocked('Remote main is unavailable');
    final version = pubspecVersion(readBlob(sha, 'pubspec.yaml'));
    final release = ReleaseTag.parse(
      '${channel == 'rc' ? 'rc/' : ''}$platform/v$version',
    );
    validateProduction(release, environment);
    // The approved source must contain this release contract, not an older
    // pipeline that could omit the common-counter/pubspec checks.
    readBlob(sha, 'tool/release/cli.dart');
    readNotesFrom(release, (path) => readBlob(sha, path));
    validateTags(release, sha, refs);
    validateStores(release, sha, refs);
    // Presence of the actual source-side guards, not proof of cloud readiness.
    final workflow = readBlob(
      sha,
      platform == 'android'
          ? '.github/workflows/android-release.yml'
          : 'codemagic.yaml',
    );
    for (final guard in [
      'release.dart ci',
      'PRODUCTION_PUBLISHING_ENABLED',
      platform == 'android' ? 'verify_android.dart' : 'verify_ios.py',
      platform == 'android' ? 'play.rb preflight' : 'ios_store.py preflight',
    ]) {
      if (!workflow.contains(guard) &&
          // Codemagic passes the gate from the protected environment to Dart.
          !(guard == 'PRODUCTION_PUBLISHING_ENABLED' &&
              platform == 'ios' &&
              readBlob(
                sha,
                'tool/release/release.dart',
              ).contains('validateProduction'))) {
        blocked('Selected main workflow is missing required guard: $guard');
      }
    }
    final config =
        jsonDecode(readBlob(sha, 'tool/release/production.json')) as Map;
    if (config['APP_ENV'] != 'production' ||
        config['API_BASE_URL'] != 'https://api.prokat.auyltech.kz' ||
        config['ENABLE_FIREBASE_SERVICES'] != 'true') {
      blocked('Production API/Firebase configuration is not approved');
    }
    if (platform == 'ios' &&
        !RegExp(r'<key>ITSAppUsesNonExemptEncryption</key>\s*<false\s*/>')
            .hasMatch(readBlob(sha, 'ios/Runner/Info.plist'))) {
      blocked('iOS Export Compliance Boolean false is missing');
    }
    final fresh = snapshot();
    if (fresh['refs/heads/main'] != sha) {
      blocked('Remote main changed during preparation; retry');
    }
    validateTags(release, sha, fresh);
    return ReleasePlan(release, sha, fresh);
  }

  void validateTags(ReleaseTag release, String sha, Map<String, String> refs) {
    final local = runGit(['tag', '--list'])
        .split('\n')
        .where((s) => s.isNotEmpty);
    final commits = releaseCommits(refs);
    if (local.contains(release.tag) || commits.containsKey(release.tag)) {
      blocked(
        'Tag already exists: ${release.tag}. Never move/delete it; inspect its run/store state',
      );
    }
    // Local unpublished reservations also count; never ignore a failed push.
    for (final name in local) {
      ReleaseTag previous;
      try {
        previous = ReleaseTag.parse(name);
      } on ReleaseFailure {
        continue;
      }
      final commit = runGit([
        'rev-parse',
        'refs/tags/${previous.tag}^{commit}',
      ]);
      if (commits.containsKey(name) && commits[name] != commit) {
        blocked('Local/remote release tag differs: $name');
      }
      commits[name] = commit;
    }
    validateBuildHistory(
      release,
      commits.keys,
      revision: sha,
      commits: commits,
    );
  }

  void validateStores(
    ReleaseTag release,
    String sha,
    Map<String, String> snapshot,
  ) {
    // Conservative historical lower bounds, never claims of live availability.
    var maximum = 18;
    for (final entry in storeStates.entries) {
      final state = entry.value;
      final floor = state['historical_floor'];
      if (floor is! int || floor < 0) blocked('Malformed cached store floor');
      final codes = <int>[floor];
      if (entry.key == 'android') {
        if (state['package'] != 'com.auyltech.prokat') {
          blocked('Cached Play identity mismatch');
        }
        for (final code in state['codes'] as List) {
          if (code is! int || code <= 0) blocked('Malformed cached Play code');
          codes.add(code);
        }
      } else {
        if (state['app_id'].toString() != '6817078475') {
          blocked('Cached Apple identity mismatch');
        }
        for (final bucket in ['builds', 'uploads']) {
          for (final item in state[bucket] as List) {
            final attributes = item['attributes'] as Map;
            final value =
                attributes[bucket == 'builds' ? 'version' : 'cfBundleVersion'];
            final number = int.tryParse(value.toString());
            if (number == null || number <= 0) {
              blocked('Malformed cached Apple build');
            }
            codes.add(number);
          }
        }
      }
      if (codes.any((code) => code > maximum)) {
        maximum = codes.reduce((a, b) => a > b ? a : b);
      }
      if (entry.key == release.platform && codes.contains(release.build)) {
        blocked(
          'Build already observed in selected store. No binary re-upload; promotion/recovery requires owner action',
        );
      }
    }
    if (release.build < maximum || release.build <= 18) {
      blocked(
        'Common build is below known store history ($maximum); live availability still requires CI',
      );
    }
    // Equality from the OTHER store is possible only with an exact paired tag,
    // already checked against remote/local history; require that provenance.
    if (release.build == maximum) {
      final other = release.platform == 'android' ? 'ios' : 'android';
      final refs = releaseCommits(snapshot);
      final same = '${release.version}+${release.build}';
      if (!refs.keys.any(
        (name) =>
            (name == 'rc/$other/v$same' || name == '$other/v$same') &&
            refs[name] == sha,
      )) {
        blocked('Equal other-store build has no paired release provenance');
      }
    }
  }

  void execute(ReleasePlan plan, {required bool dryRun}) {
    printLine(plan.preview);
    printLine(
      'Store availability is UNKNOWN locally; CI rechecks live before build and upload.',
    );
    if (dryRun) {
      printLine('DRY RUN: no files, refs, tags or uploads changed.');
      return;
    }
    if (confirm('Continue? [y/N]')?.toLowerCase() != 'y') {
      printLine('Cancelled; checkout, refs and tags unchanged.');
      return;
    }
    if (plan.release.production &&
        confirm('Type PUBLISH PRODUCTION to authorize:') !=
            'PUBLISH PRODUCTION') {
      printLine('Cancelled; checkout, refs and tags unchanged.');
      return;
    }
    clean();
    validateProduction(plan.release, environment);
    final fresh = snapshot();
    if (fresh['refs/heads/main'] != plan.sha) {
      blocked('Remote main changed; rerun and review the new plan');
    }
    validateTags(plan.release, plan.sha, fresh);
    // No checkout/branch push; update only the remote-tracking ref after consent.
    runGit([
      'fetch',
      '--no-tags',
      'origin',
      'refs/heads/main:refs/remotes/origin/main',
    ]);
    if (runGit(['rev-parse', 'refs/remotes/origin/main^{commit}']) !=
        plan.sha) {
      blocked('Main changed during fetch; no tag created');
    }
    final last = snapshot();
    if (last['refs/heads/main'] != plan.sha) {
      blocked('Remote main changed; no tag created');
    }
    validateTags(plan.release, plan.sha, last);
    final ref = 'refs/tags/${plan.release.tag}';
    runGit([
      'tag',
      '-a',
      plan.release.tag,
      plan.sha,
      '-m',
      'PROKAT ${plan.release.platform} ${plan.release.channel} ${plan.release.version}+${plan.release.build}',
    ]);
    try {
      runGit(['push', 'origin', '$ref:$ref']);
    } on Object {
      blocked(
        'Tag retained locally: ${plan.release.tag}. Push outcome UNKNOWN. '
        'Run git ls-remote --tags origin "$ref" "$ref^{}"; inspect CI/store. '
        'If absent, revalidate main/history and retry ONLY git push origin "$ref:$ref". '
        'If present verify peeled SHA ${plan.sha}; never force/delete/re-upload blindly.',
      );
    }
    printLine(
      'Pushed ${plan.release.tag} at ${plan.sha}. Inspect CI and store results; publication is not proven.',
    );
  }
}

void main(List<String> args) {
  Directory? inspection;
  try {
    if (args.length < 2 ||
        args.length > 3 ||
        (args.length == 3 && args.last != '--dry-run')) {
      blocked(
        'Usage: dart tool/release/cli.dart android|ios rc|production [--dry-run]',
      );
    }
    final root = git(['rev-parse', '--show-toplevel']);
    String run(List<String> args) => git(args, directory: root);
    if (run(['status', '--porcelain=v1', '--untracked-files=all']).isNotEmpty) {
      blocked('Working tree/index must be clean');
    }
    final url = run(['remote', 'get-url', 'origin']);
    if (!RegExp(r'[:/]auyltech/prokat(?:\.git)?$').hasMatch(url)) {
      blocked('origin must identify auyltech/prokat');
    }
    final dryRun = args.contains('--dry-run');
    String read(String sha, String path) {
      if (dryRun) {
        try {
          run(['cat-file', '-e', '$sha^{commit}']);
        } on ReleaseFailure {
          blocked(
            'Dry-run cannot read current main blob $path. Refresh the local object cache with git fetch origin main, then retry; dry-run never fetches/writes',
          );
        }
        return readGitBlob(root, sha, path);
      }
      // An isolated disposable object cache keeps cancellation non-mutating
      // for the owner's checkout, index, refs and object database.
      if (inspection == null) {
        inspection = Directory.systemTemp.createTempSync(
          'prokat-release-inspect-',
        );
        git(['init', '--bare', inspection!.path]);
        git([
          'fetch',
          '--no-tags',
          '--depth=1',
          url,
          'refs/heads/main',
        ], directory: inspection!.path);
        if (git([
              'rev-parse',
              'FETCH_HEAD^{commit}',
            ], directory: inspection!.path) !=
            sha) {
          blocked('Remote main changed during inspection; retry');
        }
      }
      return readGitBlob(inspection!.path, sha, path);
    }

    final states = <String, Map<String, dynamic>>{};
    for (final entry in {'android': 'play', 'ios': 'apple'}.entries) {
      final file = File('$root/build/release/${entry.value}-state.json');
      if (file.existsSync()) {
        states[entry.key] =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      }
    }
    final cli = ReleaseCli(
      runGit: run,
      readBlob: read,
      environment: Platform.environment,
      storeStates: states,
      confirm: (prompt) {
        stdout.write('$prompt ');
        return stdin.readLineSync();
      },
      printLine: stdout.writeln,
    );
    cli.execute(cli.plan(args[0], args[1]), dryRun: dryRun);
  } on Object catch (error) {
    stderr.writeln(
      error is ReleaseFailure
          ? error
          : 'BLOCKED: Release input/IO validation failed (${error.runtimeType}); no automatic recovery',
    );
    exitCode = 1;
  } finally {
    // Only the exact unique temporary directory allocated above, never repo data.
    inspection?.deleteSync(recursive: true);
  }
}

String readGitBlob(String directory, String sha, String path) {
  final result = Process.runSync(
    'git',
    ['show', '$sha:$path'],
    workingDirectory: directory,
    stdoutEncoding: null,
    environment: {'GIT_OPTIONAL_LOCKS': '0', 'GIT_NO_LAZY_FETCH': '1'},
  );
  if (result.exitCode != 0) blocked('Cannot read approved main blob: $path');
  return releaseText(result.stdout as List<int>);
}
