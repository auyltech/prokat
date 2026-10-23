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

const resumeTagPrompt = 'Type the full tag name to push it:';

/// `ls-remote` for one annotated tag. Only an empty listing or the exact
/// tag object plus peeled commit are conclusive.
String _classifyRemoteTag(
  String text, {
  required String tagRef,
  required String objectId,
  required String expectSha,
}) {
  final parsed = <List<String>>[];
  for (final raw in text.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    final match = RegExp(r'^([0-9a-f]{40})[ \t]+(\S+)$').firstMatch(line);
    if (match == null) return 'REMOTE_UNKNOWN';
    parsed.add([match[1]!, match[2]!]);
  }
  if (parsed.isEmpty) return 'REMOTE_ABSENT';
  final same =
      parsed.length == 2 &&
      parsed.any((row) => row[0] == objectId && row[1] == tagRef) &&
      parsed.any((row) => row[0] == expectSha && row[1] == '$tagRef^{}') &&
      parsed[0][1] != parsed[1][1];
  return same ? 'REMOTE_SAME' : 'REMOTE_DIFFERS';
}

class ReleasePlan {
  ReleasePlan(this.release, this.sha, this.refs, {required this.dryRun});
  final ReleaseTag release;
  final String sha;
  final Map<String, String> refs;
  final bool dryRun;
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
    required this.confirm,
    required this.printLine,
    this.storeStates = const {},
  });
  final GitRunner runGit;
  final BlobReader readBlob;
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

  ReleasePlan plan(String platform, String channel, {required bool dryRun}) {
    if (!{'android', 'ios'}.contains(platform) ||
        !{'rc', 'production'}.contains(channel)) {
      blocked('Unknown command');
    }
    clean();
    final refs = snapshot();
    final sha =
        refs['refs/heads/main'] ?? blocked('Remote main is unavailable');
    if (dryRun) requireFreshLocalMain(sha);
    final version = pubspecVersion(readBlob(sha, 'pubspec.yaml'));
    final release = ReleaseTag.parse(
      '${channel == 'rc' ? 'rc/' : ''}$platform/v$version',
    );
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
    if (channel == 'production' && platform == 'android') {
      if (!workflow.contains('GITHUB_RUN_ATTEMPT')) {
        blocked(
          'Selected main workflow is missing required guard: GITHUB_RUN_ATTEMPT',
        );
      }
      if (workflow.contains('PRODUCTION_RELEASE_AUTH_ANDROID')) {
        blocked(
          'Selected main still requires per-release PRODUCTION_RELEASE_AUTH_ANDROID; merge the automated production CLI first',
        );
      }
    }
    if (channel == 'production' && platform == 'ios') {
      final source = readBlob(sha, 'tool/release/release.dart');
      for (final guard in ['validateCloudAuthorization', 'CM_TRIGGER_SOURCE']) {
        if (!source.contains(guard)) {
          blocked('Selected main workflow is missing required guard: $guard');
        }
      }
      if (source.contains('PRODUCTION_RELEASE_AUTH_IOS')) {
        blocked(
          'Selected main still requires per-release PRODUCTION_RELEASE_AUTH_IOS; merge the automated production CLI first',
        );
      }
      if (!workflow.contains('event.repository.full_name')) {
        blocked(
          'Selected main workflow is missing required guard: event.repository.full_name',
        );
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
    return ReleasePlan(release, sha, fresh, dryRun: dryRun);
  }

  /// Dry-run reads blobs only for the SHA just returned by ls-remote, and only
  /// when the local tracking ref already names that same commit.
  void requireFreshLocalMain(String sha) {
    String local;
    try {
      local = runGit([
        'rev-parse',
        '--verify',
        'refs/remotes/origin/main^{commit}',
      ]);
    } on ReleaseFailure {
      blocked(
        'Local origin/main is missing; run git fetch origin main outside the CLI and retry',
      );
    }
    if (local != sha) {
      blocked(
        'Local origin/main is stale ($local) vs remote ($sha); run git fetch origin main outside the CLI and retry',
      );
    }
    try {
      runGit(['cat-file', '-e', '$sha^{commit}']);
    } on ReleaseFailure {
      blocked(
        'Dry-run cannot read approved commit $sha. Refresh the local object cache with git fetch origin main outside the CLI; dry-run never fetches',
      );
    }
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
      final paired = '${release.production ? '' : 'rc/'}$other/v$same';
      if (!refs.keys.any((name) => name == paired && refs[name] == sha)) {
        blocked('Equal other-store build has no paired release provenance');
      }
    }
  }

  void execute(ReleasePlan plan, {required bool dryRun}) {
    if (dryRun != plan.dryRun) {
      blocked(
        'Dry-run plan cannot be executed and a real plan cannot be previewed as dry-run; rebuild the plan',
      );
    }
    printLine(plan.preview);
    if (plan.release.production) {
      printLine(
        'Cloud production uses the permanent PRODUCTION_PUBLISHING_ENABLED gate and this tag push. Per-release authorization variables are not used.',
      );
      printLine(
        'Server tag ruleset is a U5 precondition (OC-C0); not verifiable from this CLI',
      );
      printLine('Pipeline: ${pipelineWatchUrl(plan.release)}');
    }
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
    clean();
    final fresh = snapshot();
    if (fresh['refs/heads/main'] != plan.sha) {
      blocked('Remote main changed; rerun and review the new plan');
    }
    validateTags(plan.release, plan.sha, fresh);
    // No checkout/branch push; update only the remote-tracking ref.
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
        'A failed or interrupted push is not proof the tag is unpublished. '
        'Re-classify with: dart tool/release/cli.dart ${plan.release.platform} ${plan.release.channel} '
        '--resume-push ${plan.release.tag} --expect-sha ${plan.sha}',
      );
    }
    printLine('Pushed ${plan.release.tag} at ${plan.sha}.');
    printLine('Pipeline: ${pipelineWatchUrl(plan.release)}');
    printLine('Inspect CI and store results; publication is not proven.');
  }

  /// Read-only recovery after an ambiguous tag push. One exact refspec push
  /// happens only for `REMOTE_ABSENT` after a fresh main/history check and an
  /// exact tag-name confirmation.
  void resumePush({
    required String platform,
    required String channel,
    required String tag,
    required String expectSha,
    required bool dryRun,
  }) {
    if (!{'android', 'ios'}.contains(platform) ||
        !{'rc', 'production'}.contains(channel)) {
      blocked('Unknown command');
    }
    final release = ReleaseTag.parse(tag);
    if (release.platform != platform || release.channel != channel) {
      blocked('Resume tag $tag does not match $platform $channel');
    }
    if (!RegExp(r'^[0-9a-f]{40}$').hasMatch(expectSha)) {
      blocked('Expected SHA must be 40 lowercase hex characters');
    }
    final tagRef = 'refs/tags/${release.tag}';
    final type = _localTagField(['cat-file', '-t', tagRef]);
    final objectId = _localTagField(['rev-parse', tagRef]);
    final peeled = _localTagField(['rev-parse', '$tagRef^{commit}']);
    if (type != 'tag' ||
        !RegExp(r'^[0-9a-f]{40}$').hasMatch(objectId) ||
        peeled != expectSha) {
      blocked(
        'LOCAL_TAG_MISMATCH: annotated tag is missing or does not peel to --expect-sha',
      );
    }
    final kind = _readRemoteTag(tagRef, objectId, expectSha);
    if (kind == 'REMOTE_SAME') {
      _printRemoteSame();
      return;
    }
    if (kind == 'REMOTE_DIFFERS') {
      blocked(
        'REMOTE_DIFFERS: the remote tag does not match the local annotated object and expected commit. '
        'Stop for manual inspection. Nothing was changed.',
      );
    }
    if (kind != 'REMOTE_ABSENT') {
      blocked(
        'REMOTE_UNKNOWN: remote tag state is not established. Stop and retry only a later read. Nothing was changed.',
      );
    }
    if (dryRun) {
      printLine(
        'REMOTE_ABSENT: origin has no $tagRef. Dry-run does not push or prompt. '
        'A missing workflow run is not proof that no run was created.',
      );
      return;
    }
    final remoteMain = _remoteMain();
    if (remoteMain != expectSha) {
      blocked(
        'MAIN_MOVED_NEW_NUMBER_REQUIRED: remote main is not the expected commit. '
        'Discard this build number for a new release. The local tag remains and was not pushed.',
      );
    }
    _requireRemoteHistory(release, expectSha);
    printLine('REMOTE_ABSENT: origin has no $tagRef.');
    printLine(
      'This command cannot see provider runs. A missing workflow run is not proof that no run was created. '
      'If a run exists, or you cannot establish that none was created, do not type the tag name.',
    );
    if (release.production) {
      printLine('Pipeline: ${pipelineWatchUrl(release)}');
      if (release.platform == 'android') {
        printLine(
          'Freeze Google Play Console until the provider run reaches a terminal state.',
        );
      }
    }
    if (confirm(resumeTagPrompt) != release.tag) {
      blocked('Confirmation did not match the tag. Nothing was pushed.');
    }
    try {
      runGit(['push', 'origin', '$tagRef:$tagRef']);
    } on Object {
      // A failed push is not proof that origin rejected the tag.
    }
    final after = _readRemoteTag(tagRef, objectId, expectSha);
    if (after == 'REMOTE_SAME') {
      _printRemoteSame();
      return;
    }
    blocked(
      '$after: remote tag is not a confirmed match. Stop. Another push requires a new confirmation. Nothing else was changed.',
    );
  }

  String _localTagField(List<String> args) {
    try {
      return runGit(args);
    } on ReleaseFailure {
      blocked(
        'LOCAL_TAG_MISMATCH: annotated tag is missing or does not peel to --expect-sha',
      );
    }
  }

  String _readRemoteTag(String tagRef, String objectId, String expectSha) {
    final String text;
    try {
      text = runGit(['ls-remote', 'origin', tagRef, '$tagRef^{}']);
    } on ReleaseFailure {
      blocked(
        'REMOTE_UNKNOWN: cannot read the remote tag. Stop and retry only a later read. Nothing was changed.',
      );
    }
    final kind = _classifyRemoteTag(
      text,
      tagRef: tagRef,
      objectId: objectId,
      expectSha: expectSha,
    );
    if (kind == 'REMOTE_UNKNOWN') {
      blocked(
        'REMOTE_UNKNOWN: remote tag listing is not readable. Stop and retry only a later read. Nothing was changed.',
      );
    }
    return kind;
  }

  String _remoteMain() {
    final String text;
    try {
      text = runGit(['ls-remote', 'origin', 'refs/heads/main']);
    } on ReleaseFailure {
      blocked(
        'REMOTE_UNKNOWN: cannot read remote main. Stop and retry only a later read. Nothing was changed.',
      );
    }
    final Map<String, String> refs;
    try {
      refs = remoteRefs(text);
    } on ReleaseFailure {
      blocked(
        'REMOTE_UNKNOWN: remote main listing is not readable. Stop and retry only a later read. Nothing was changed.',
      );
    }
    return refs['refs/heads/main'] ??
        blocked(
          'REMOTE_UNKNOWN: remote main is unavailable. Stop and retry only a later read. Nothing was changed.',
        );
  }

  void _requireRemoteHistory(ReleaseTag release, String expectSha) {
    final String text;
    try {
      text = runGit(['ls-remote', '--tags', 'origin']);
    } on ReleaseFailure {
      blocked(
        'REMOTE_UNKNOWN: cannot read remote tags. Stop and retry only a later read. Nothing was changed.',
      );
    }
    final Map<String, String> refs;
    try {
      refs = remoteRefs(text);
    } on ReleaseFailure {
      blocked(
        'REMOTE_UNKNOWN: remote tag listing is not readable. Stop and retry only a later read. Nothing was changed.',
      );
    }
    final commits = releaseCommits(refs);
    validateBuildHistory(
      release,
      commits.keys,
      revision: expectSha,
      commits: commits,
    );
  }

  void _printRemoteSame() {
    printLine(
      'REMOTE_SAME: the remote annotated tag and peeled commit match. '
      'Do not push again. Watch the provider run. '
      'A missing workflow run is not proof that no run was created.',
    );
  }
}

void main(List<String> args) {
  Directory? inspection;
  try {
    final invocation = _parseInvocation(args);
    final dryRun = invocation.dryRun;
    final root = git(['rev-parse', '--show-toplevel']);
    String run(List<String> args) => git(args, directory: root);
    if (!invocation.resume &&
        run(['status', '--porcelain=v1', '--untracked-files=all']).isNotEmpty) {
      blocked('Working tree/index must be clean');
    }
    final url = run(['remote', 'get-url', 'origin']);
    if (!RegExp(r'[:/]auyltech/prokat(?:\.git)?$').hasMatch(url)) {
      blocked('origin must identify auyltech/prokat');
    }
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
      storeStates: states,
      confirm: (prompt) {
        stdout.write('$prompt ');
        return stdin.readLineSync();
      },
      printLine: stdout.writeln,
    );
    if (invocation.resume) {
      cli.resumePush(
        platform: invocation.platform,
        channel: invocation.channel,
        tag: invocation.tag!,
        expectSha: invocation.expectSha!,
        dryRun: dryRun,
      );
    } else {
      cli.execute(
        cli.plan(invocation.platform, invocation.channel, dryRun: dryRun),
        dryRun: dryRun,
      );
    }
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

class _Invocation {
  const _Invocation({
    required this.platform,
    required this.channel,
    required this.dryRun,
    this.tag,
    this.expectSha,
  });
  final String platform;
  final String channel;
  final bool dryRun;
  final String? tag;
  final String? expectSha;
  bool get resume => tag != null;
}

_Invocation _parseInvocation(List<String> args) {
  const usage =
      'Usage: dart tool/release/cli.dart android|ios rc|production [--dry-run]\n'
      '   or: dart tool/release/cli.dart android|ios rc|production '
      '--resume-push <tag> --expect-sha <sha> [--dry-run]';
  if (args.length < 2) blocked(usage);
  final platform = args[0];
  final channel = args[1];
  final rest = args.sublist(2);
  if (rest.isEmpty) {
    return _Invocation(platform: platform, channel: channel, dryRun: false);
  }
  if (rest.length == 1 && rest.single == '--dry-run') {
    return _Invocation(platform: platform, channel: channel, dryRun: true);
  }
  final dryRun = rest.length == 5 && rest.last == '--dry-run';
  final body = dryRun ? rest.sublist(0, 4) : rest;
  if (body.length == 4 &&
      body[0] == '--resume-push' &&
      body[2] == '--expect-sha' &&
      (rest.length == 4 || dryRun)) {
    return _Invocation(
      platform: platform,
      channel: channel,
      dryRun: dryRun,
      tag: body[1],
      expectSha: body[3],
    );
  }
  blocked(usage);
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

String pipelineWatchUrl(ReleaseTag release) {
  if (release.platform == 'android') {
    final query = Uri.encodeQueryComponent('tag:${release.tag}');
    return 'https://github.com/auyltech/prokat/actions?query=$query';
  }
  return 'https://codemagic.io/apps';
}
