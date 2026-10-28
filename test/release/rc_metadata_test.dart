import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/release/release.dart' as release;

void main() {
  test('tracked 1.2.3 notes prepare Android and iOS build 19', () {
    final root = Directory.current;
    final android = release.ReleaseTag.parse('rc/android/v1.2.3+19');
    final ios = release.ReleaseTag.parse('rc/ios/v1.2.3+19');
    final notes = release.readNotes(root, android);
    expect(release.readNotes(root, ios), notes);
    expect(notes.keys, ['ru', 'en', 'kk']);

    final temp = Directory.systemTemp.createTempSync('prokat-rc-metadata-');
    addTearDown(() => temp.deleteSync(recursive: true));
    final source = Directory('${temp.path}/releases/1.2.3')
      ..createSync(recursive: true);
    for (final name in ['ru.txt', 'en.txt', 'kk.txt']) {
      File('${root.path}/releases/1.2.3/$name')
          .copySync('${source.path}/$name');
    }
    for (final tag in [android, ios]) {
      release.prepare(tag, 'a' * 40, temp);
      final context = jsonDecode(
        File('${temp.path}/build/release/context.json').readAsStringSync(),
      ) as Map;
      expect(context['version'], '1.2.3');
      expect(context['build'], 19);
      expect(
        context['destination'],
        tag.platform == 'android' ? 'internal' : 'testflight',
      );
      for (final locale in {'ru-RU': 'ru', 'en-US': 'en', 'kk': 'kk'}.entries) {
        expect(
          File(
            '${temp.path}/build/release/play/${locale.key}/changelogs/19.txt',
          ).readAsStringSync(),
          notes[locale.value],
        );
      }
      final apple = jsonDecode(
        File('${temp.path}/build/release/apple-localizations.json')
            .readAsStringSync(),
      ) as List;
      expect(apple, release.appleNotes(notes));
      expect(
        File('${temp.path}/build/release/release.env').readAsStringSync(),
        'RELEASE_VERSION=1.2.3\nRELEASE_BUILD=19\nRELEASE_CHANNEL=rc\n',
      );
    }
  });
}
