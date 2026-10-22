import 'dart:convert';
import 'dart:io';

/// No package dependencies: usable before `flutter pub get` on any runner.
class ReleaseFailure implements Exception {
  ReleaseFailure(this.message);
  final String message;
  @override
  String toString() => 'BLOCKED: $message';
}

Never blocked(String message) => throw ReleaseFailure(message);

class ReleaseTag {
  ReleaseTag(this.tag, this.platform, this.channel, this.version, this.build);
  final String tag, platform, channel, version;
  final int build;
  bool get production => channel == 'production';

  static ReleaseTag parse(String value) {
    final match = RegExp(
      r'^(rc/)?(android|ios)/v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\+([1-9][0-9]*)$',
    ).firstMatch(value);
    if (match == null || match.end != value.length) {
      blocked(
        'Invalid release tag: expected [rc/](android|ios)/vMAJOR.MINOR.PATCH+BUILD',
      );
    }
    final version = '${match[3]}.${match[4]}.${match[5]}';
    // Conservative common store policy, not the full SemVer numeric domain.
    if (version.length > 30 || [3, 4, 5].any((i) => match[i]!.length > 4)) {
      blocked(
        'Version components must fit four digits and 30 characters total',
      );
    }
    final platform = match[2]!;
    final build = int.tryParse(match[6]!);
    // Apple single-component CFBundleVersion follows the conservative archived
    // four-digit major-component limit; this project does not map it to x.y.z.
    final maximum = platform == 'android' ? 2100000000 : 9999;
    if (build == null || build > maximum) {
      blocked('$platform build number must be between 1 and $maximum');
    }
    return ReleaseTag(
      value,
      platform,
      match[1] == null ? 'production' : 'rc',
      version,
      build,
    );
  }

  Map<String, Object> toJson() => {
    'schema': 1,
    'tag': tag,
    'platform': platform,
    'channel': channel,
    'version': version,
    'build': build,
    'destination': platform == 'android'
        ? (production ? 'production' : 'internal')
        : (production ? 'app_store_review' : 'testflight'),
  };
}

Map<String, String> options(List<String> args) {
  if (args.length.isOdd) blocked('Options must be --name value pairs');
  final result = <String, String>{};
  for (var i = 0; i < args.length; i += 2) {
    if (!args[i].startsWith('--') || result.containsKey(args[i].substring(2))) {
      blocked('Invalid or repeated option');
    }
    result[args[i].substring(2)] = args[i + 1];
  }
  return result;
}

String requiredOption(Map<String, String> args, String key) =>
    args[key] ?? blocked('Missing --$key');

String git(List<String> args, {String? directory}) {
  final result = Process.runSync(
    'git',
    args,
    workingDirectory: directory,
    environment: {'GIT_OPTIONAL_LOCKS': '0', 'GIT_NO_LAZY_FETCH': '1'},
  );
  if (result.exitCode != 0) {
    // Never echo credential-bearing remote URLs or arbitrary git stderr.
    blocked(
      'Git ${args.first} failed (exit ${result.exitCode}); check repository access/history',
    );
  }
  return (result.stdout as String).trim();
}

void validateProduction(ReleaseTag release, Map<String, String> env) {
  if (release.production && env['PRODUCTION_PUBLISHING_ENABLED'] != 'true') {
    blocked('Production publishing is disabled until owner gate U5');
  }
}

void validateBuildHistory(
  ReleaseTag release,
  Iterable<String> tags, {
  String? revision,
  Map<String, String> commits = const {},
}) {
  for (final name in tags) {
    if (name == release.tag) continue;
    ReleaseTag previous;
    try {
      previous = ReleaseTag.parse(name);
    } on ReleaseFailure {
      continue; // Legacy/archive/unrelated tags do not claim a build number.
    }
    if (previous.build == release.build &&
        previous.platform != release.platform &&
        previous.channel == release.channel &&
        previous.version == release.version &&
        revision != null &&
        commits[name] == revision) {
      continue; // The other platform of the same channel, version and SHA.
    }
    if (previous.build >= release.build) {
      blocked(
        previous.build == release.build && previous.channel != release.channel
            ? 'Build ${release.build} already used by $name in another channel; RC and production never share a build. Bump pubspec.'
            : previous.build == release.build &&
                  previous.platform == release.platform
            ? 'Build already reserved by $name. RC-to-production promotion is not implemented; do not re-upload an accepted binary.'
            : 'Common build must exceed release tags on BOTH platforms (or pair the same version/build/SHA and channel): $name',
      );
    }
  }
}

void validateEvent(ReleaseTag release, Map<String, String> env) {
  if (release.platform == 'android') {
    if (env['GITHUB_ACTIONS'] != 'true' ||
        env['GITHUB_REPOSITORY'] != 'auyltech/prokat' ||
        env['GITHUB_EVENT_NAME'] != 'push' ||
        env['GITHUB_REF_TYPE'] != 'tag' ||
        env['GITHUB_REF'] != 'refs/tags/${release.tag}') {
      blocked('Android release requires a GitHub tag push');
    }
    final payload = jsonDecode(
      File(env['GITHUB_EVENT_PATH'] ?? '').readAsStringSync(),
    ) as Map;
    if (payload['deleted'] != false ||
        payload['ref'] != 'refs/tags/${release.tag}') {
      blocked('Tag deletion or mismatched webhook cannot publish');
    }
  } else if ((env['CM_BUILD_ID'] ?? '').isEmpty ||
      env['CM_TAG'] != release.tag ||
      env['CM_REPO_SLUG'] != 'auyltech/prokat' ||
      env['CM_PULL_REQUEST'] != 'false') {
    // Codemagic documents CM_TAG as set only for a tag webhook. Manual/API/UI
    // builds without this webhook context fail before any build/sign/store step.
    blocked('iOS release requires Codemagic tag webhook context (CM_TAG)');
  }
}

void validateRevision(
  ReleaseTag release,
  String revision, {
  required bool ci,
  String? directory,
}) {
  String runGit(List<String> args) => git(args, directory: directory);
  if (!RegExp(r'^[0-9a-f]{40}$').hasMatch(revision)) {
    blocked(
      'Specify an explicit approved 40-character commit SHA with --revision',
    );
  }
  if (runGit(['rev-parse', 'HEAD']) != revision) {
    blocked('Checkout differs from approved revision');
  }
  if (runGit(['status', '--porcelain', '--untracked-files=no']).isNotEmpty) {
    blocked(
      'Tracked worktree changes must be committed before preparing a release',
    );
  }
  // Every channel must use a real commit reachable from freshly fetched main.
  // A cached ref or incomplete history cannot authorize an RC or production.
  if (runGit(['rev-parse', '--is-shallow-repository']) == 'true') {
    runGit(['fetch', '--unshallow', 'origin']);
    if (runGit(['rev-parse', '--is-shallow-repository']) != 'false') {
      blocked('Cannot obtain complete Git history for release ancestry');
    }
  }
  runGit([
    'fetch',
    '--no-tags',
    'origin',
    'refs/heads/main:refs/remotes/origin/main',
  ]);
  runGit(['rev-parse', '--verify', 'refs/remotes/origin/main^{commit}']);
  final ancestry = Process.runSync('git', [
    'merge-base',
    '--is-ancestor',
    revision,
    'refs/remotes/origin/main',
  ], workingDirectory: directory);
  if (ancestry.exitCode != 0) {
    blocked('Release commit is not reachable from current origin/main');
  }
  if (ci) {
    runGit(['fetch', '--tags', 'origin']);
    final tags = runGit(['tag', '--list']).split('\n');
    validateBuildHistory(
      release,
      tags,
      revision: revision,
      commits: {
        for (final name in tags.where((name) => name.isNotEmpty))
          name: runGit(['rev-parse', 'refs/tags/$name^{commit}']),
      },
    );
    final ref = 'refs/tags/${release.tag}';
    if (runGit(['rev-parse', '$ref^{commit}']) != revision) {
      blocked('Local tag differs from checkout');
    }
    final lines = runGit(['ls-remote', '--exit-code', 'origin', ref, '$ref^{}'])
        .split('\n');
    final peeled = lines.where((line) => line.trim().endsWith('$ref^{}'));
    final matching = peeled.isNotEmpty ? peeled.single : lines.single;
    if (matching.split(RegExp(r'\s+')).first != revision) {
      blocked('Remote tag changed or does not match the webhook commit');
    }
  }
}

Map<String, String> readNotes(Directory root, ReleaseTag release) {
  return readNotesFrom(release, (path) {
    final file = File('${root.path}/$path');
    if (!file.existsSync()) blocked('Missing $path');
    return releaseText(file.readAsBytesSync());
  });
}

String releaseText(List<int> bytes) {
  if (bytes.length >= 3 &&
      bytes[0] == 239 &&
      bytes[1] == 187 &&
      bytes[2] == 191) {
    blocked('Release text must be UTF-8 without BOM');
  }
  return utf8.decode(bytes);
}

/// Shared parser for disk-based CI and immutable Git blobs in the owner CLI.
Map<String, String> readNotesFrom(
  ReleaseTag release,
  String Function(String path) read,
) {
  final base = 'releases/${release.version}';
  final metadata = jsonDecode(read('$base/release.json')) as Map;
  if (metadata['schema'] != 1 ||
      metadata['version'] != release.version ||
      metadata['ready'] != true) {
    blocked(
      'Release metadata must have schema=1, matching version and ready=true',
    );
  }
  final notes = <String, String>{};
  for (final language in ['ru', 'en', 'kk']) {
    final raw = read('$base/$language.txt');
    if (raw.startsWith('\uFEFF')) {
      blocked('Save $language.txt as UTF-8 without BOM');
    }
    final text = raw.replaceAll('\r\n', '\n').trim();
    if (text.isEmpty ||
        text.startsWith('\uFEFF') ||
        RegExp(r'[\x00-\x08\x0B-\x1F\x7F<>]').hasMatch(text) ||
        RegExp(
          r'TODO|REPLACE_ME|PLACEHOLDER',
          caseSensitive: false,
        ).hasMatch(text)) {
      blocked(
        'Invalid/empty/placeholder release notes in $language.txt; plain UTF-8 text required',
      );
    }
    // Use the stricter Google limit for the common source; UTF-16 length is
    // conservative for emoji versus stores counting Unicode code points.
    if (text.length > 500) {
      blocked('$language.txt exceeds the common 500-character limit');
    }
    notes[language] = text;
  }
  return notes;
}

String pubspecVersion(String text) {
  final lines = RegExp(
    r'^version:\s*([^\r\n#]+)',
    multiLine: true,
  ).allMatches(text).toList();
  if (lines.length != 1) {
    blocked('Expected one version: X.Y.Z+N in pubspec.yaml');
  }
  final version = lines.single[1]!.trim();
  // A common counter must also fit Apple's limit, even for Android-only retry.
  ReleaseTag.parse('rc/ios/v$version');
  return version;
}

void validatePubspecVersion(ReleaseTag release, String text) {
  if (pubspecVersion(text) != '${release.version}+${release.build}') {
    blocked('Tag version/build differs from tagged pubspec.yaml');
  }
}

List<Map<String, String>> appleNotes(Map<String, String> notes) => [
  {'locale': 'ru', 'whats_new': notes['ru']!},
  {'locale': 'en-US', 'whats_new': notes['en']!},
  {'locale': 'en-GB', 'whats_new': notes['en']!},
];

void writeJson(String path, Object value) {
  final file = File(path)..parent.createSync(recursive: true);
  file.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(value)}\n',
  );
}

void prepare(ReleaseTag release, String revision, Directory root) {
  final notes = readNotes(root, release);
  final out = '${root.path}/build/release';
  writeJson('$out/context.json', {...release.toJson(), 'commit': revision});
  File('$out/release.env').writeAsStringSync(
    'RELEASE_VERSION=${release.version}\nRELEASE_BUILD=${release.build}\n'
    'RELEASE_CHANNEL=${release.channel}\n',
  );
  writeJson('$out/apple-localizations.json', appleNotes(notes));
  for (final entry in {'ru-RU': 'ru', 'en-US': 'en', 'kk': 'kk'}.entries) {
    final file = File('$out/play/${entry.key}/changelogs/${release.build}.txt');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(notes[entry.value]!);
  }
}

void main(List<String> args) {
  try {
    if (args.isEmpty) {
      blocked('Usage: dart tool/release/release.dart init|check|ci --...');
    }
    final command = args.first;
    final opts = options(args.skip(1).toList());
    if (command == 'init') {
      final version = requiredOption(opts, 'version');
      ReleaseTag.parse('rc/android/v$version+1');
      final directory = Directory('releases/$version');
      if (directory.existsSync()) blocked('Release directory already exists');
      writeJson('${directory.path}/release.json', {
        'schema': 1,
        'version': version,
        'ready': false,
      });
      for (final language in ['ru', 'en', 'kk']) {
        File('${directory.path}/$language.txt').writeAsStringSync('');
      }
      stdout.writeln(
        'Draft created; fill all translations and set ready=true after review',
      );
      return;
    }
    if (!{'check', 'ci'}.contains(command)) blocked('Unknown command');
    final release = ReleaseTag.parse(requiredOption(opts, 'tag'));
    if (release.platform != requiredOption(opts, 'platform') ||
        release.channel != requiredOption(opts, 'channel')) {
      blocked('Tag platform/channel does not match the selected workflow');
    }
    if (command == 'ci') {
      validateEvent(release, Platform.environment);
      validateProduction(release, Platform.environment);
    }
    final revision = requiredOption(opts, 'revision');
    validateRevision(release, revision, ci: command == 'ci');
    if (command == 'ci') {
      validatePubspecVersion(release, File('pubspec.yaml').readAsStringSync());
    }
    prepare(release, revision, Directory.current);
    stdout.writeln(jsonEncode({...release.toJson(), 'commit': revision}));
  } on Object catch (error) {
    stderr.writeln(
      error is ReleaseFailure
          ? error
          : 'BLOCKED: Release input/IO validation failed (${error.runtimeType})',
    );
    exitCode = 1;
  }
}
