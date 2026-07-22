import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const arbPaths = <String>[
    'lib/l10n/app_en.arb',
    'lib/l10n/app_ru.arb',
    'lib/l10n/app_kk.arb',
  ];

  test('ARB files have unique top-level keys and matching messages', () {
    final messageKeysByFile = <String, Set<String>>{};

    for (final path in arbPaths) {
      final source = File(path).readAsStringSync();
      final topLevelKeys = RegExp(
        r'^  "([^"]+)"\s*:',
        multiLine: true,
      ).allMatches(source).map((match) => match.group(1)!).toList();

      final duplicates = <String>{};
      final seen = <String>{};
      for (final key in topLevelKeys) {
        if (!seen.add(key)) duplicates.add(key);
      }

      expect(duplicates, isEmpty, reason: '$path contains duplicate keys');

      final decoded = jsonDecode(source) as Map<String, dynamic>;
      messageKeysByFile[path] = decoded.keys
          .where((key) => !key.startsWith('@'))
          .toSet();
    }

    final templateKeys = messageKeysByFile[arbPaths.first]!;
    for (final path in arbPaths.skip(1)) {
      expect(
        messageKeysByFile[path],
        templateKeys,
        reason: '$path must contain exactly the English template messages',
      );
    }
  });
}
