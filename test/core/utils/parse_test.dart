import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/utils/parse.dart';

void main() {
  group('parseNullableInt', () {
    test('keeps ints', () {
      expect(parseNullableInt(4), 4);
    });

    test('rounds JSON doubles such as ratingAverage', () {
      expect(parseNullableInt(4.5), 5);
      expect(parseNullableInt(4.0), 4);
    });

    test('parses numeric strings', () {
      expect(parseNullableInt('4'), 4);
      expect(parseNullableInt('4.5'), 5);
      expect(parseNullableInt(''), isNull);
    });

    test('returns null for missing values', () {
      expect(parseNullableInt(null), isNull);
    });
  });
}
