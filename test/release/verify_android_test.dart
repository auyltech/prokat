import 'package:flutter_test/flutter_test.dart';

import '../../tool/release/release.dart';
import '../../tool/release/verify_android.dart';

void main() {
  test('targetSdk at or above 36 is accepted', () {
    requireTargetSdk('36');
    requireTargetSdk('37');
    requireTargetSdk(' 36\n');
  });

  test('targetSdk below 36 or unreadable is blocked', () {
    for (final dumped in ['35', '', 'abc', '-1']) {
      expect(
        () => requireTargetSdk(dumped),
        throwsA(
          isA<ReleaseFailure>().having(
            (error) => error.message,
            'message',
            contains('targetSdkVersion must be at least 36'),
          ),
        ),
      );
    }
  });
}
