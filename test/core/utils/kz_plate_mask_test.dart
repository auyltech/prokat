import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/utils/kz_plate_mask.dart';

void main() {
  test('sanitizeKzPlate keeps latin letters, digits and spaces', () {
    expect(sanitizeKzPlate('123abc06'), '123ABC06');
    expect(sanitizeKzPlate('01 ABC 1234'), '01 ABC 1234');
  });

  test('sanitizeKzPlate rejects cyrillic and punctuation', () {
    expect(sanitizeKzPlate('123АВС06'), '12306');
    expect(sanitizeKzPlate('12-3#AB'), '123AB');
  });
}
