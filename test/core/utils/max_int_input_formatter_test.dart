import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/utils/max_int_input_formatter.dart';

void main() {
  const formatter = MaxIntInputFormatter(100000);

  TextEditingValue apply(String oldText, String newText) {
    return formatter.formatEditUpdate(
      TextEditingValue(text: oldText),
      TextEditingValue(text: newText),
    );
  }

  test('allows empty and values up to the max', () {
    expect(apply('10000', '').text, '');
    expect(apply('10000', '100000').text, '100000');
  });

  test('rejects the extra digit that would exceed the max', () {
    expect(apply('100000', '1000001').text, '100000');
    expect(apply('10000', '100001').text, '10000');
  });
}
