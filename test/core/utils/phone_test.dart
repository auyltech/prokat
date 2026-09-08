import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/utils/format.dart';

void main() {
  test('normalizeKzPhone stores Kazakhstan numbers as E.164', () {
    expect(normalizeKzPhone('+77051111111'), '+77051111111');
    expect(normalizeKzPhone('+7 (705) 111-11-11'), '+77051111111');
    expect(normalizeKzPhone('+7(705)111-11-11'), '+77051111111');
    expect(normalizeKzPhone('8 705 111 11 11'), '+77051111111');
    expect(normalizeKzPhone('7051111111'), '+77051111111');
    expect(normalizeKzPhone('77051111111'), '+77051111111');
  });

  test('normalizeKzPhone rejects empty and incomplete numbers', () {
    expect(normalizeKzPhone(null), isNull);
    expect(normalizeKzPhone(''), isNull);
    expect(normalizeKzPhone('12345'), isNull);
    expect(normalizeKzPhone('+770511111'), isNull);
  });
}
