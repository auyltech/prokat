import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/utils/kz_phone_mask.dart';

TextEditingValue _apply(
  KzPhoneMaskFormatter formatter,
  String from,
  String to,
) {
  return formatter.formatEditUpdate(
    TextEditingValue(
      text: from,
      selection: TextSelection.collapsed(offset: from.length),
    ),
    TextEditingValue(
      text: to,
      selection: TextSelection.collapsed(offset: to.length),
    ),
  );
}

void main() {
  test('nationalKzPhoneDigits strips country code and mask chars', () {
    expect(nationalKzPhoneDigits(''), '');
    expect(nationalKzPhoneDigits('+7'), '');
    expect(nationalKzPhoneDigits('+7(7'), '7');
    expect(nationalKzPhoneDigits('+7(705)111-11-11'), '7051111111');
    expect(nationalKzPhoneDigits('+77051111111'), '7051111111');
    expect(nationalKzPhoneDigits('87051111111'), '7051111111');
    expect(nationalKzPhoneDigits('7051111111'), '7051111111');
  });

  test('formatKzPhoneMask builds +7(###)###-##-## progressively', () {
    expect(formatKzPhoneMask(''), '+7');
    expect(formatKzPhoneMask('7'), '+7(7');
    expect(formatKzPhoneMask('705'), '+7(705)');
    expect(formatKzPhoneMask('705111'), '+7(705)111');
    expect(formatKzPhoneMask('70511111'), '+7(705)111-11');
    expect(formatKzPhoneMask('7051111111'), '+7(705)111-11-11');
    expect(formatKzPhoneMask('7051111111999'), '+7(705)111-11-11');
  });

  test('KzPhoneMaskFormatter keeps +7 and rejects extra digits', () {
    final formatter = KzPhoneMaskFormatter();

    expect(_apply(formatter, '+7', '').text, '+7');
    expect(_apply(formatter, '+7', '+77').text, '+7(7');
    expect(_apply(formatter, '+7(70', '+7(705').text, '+7(705)');
    expect(_apply(formatter, '+7', '+77051111111').text, '+7(705)111-11-11');
    expect(
      _apply(formatter, '+7(705)111-11-11', '+7(705)111-11-11999').text,
      '+7(705)111-11-11',
    );
  });

  test('backspace over a mask separator deletes the digit before it', () {
    final formatter = KzPhoneMaskFormatter();

    final afterBracket = _apply(formatter, '+7(706)', '+7(706');
    expect(afterBracket.text, '+7(70');
    expect(afterBracket.selection.baseOffset, afterBracket.text.length);

    final afterDash = formatter.formatEditUpdate(
      const TextEditingValue(
        text: '+7(705)111-11-11',
        selection: TextSelection.collapsed(offset: 11),
      ),
      const TextEditingValue(
        text: '+7(705)11111-11',
        selection: TextSelection.collapsed(offset: 10),
      ),
    );
    expect(afterDash.text, '+7(705)111-11-1');
    expect(afterDash.selection.baseOffset, 9);

    final midText = formatter.formatEditUpdate(
      const TextEditingValue(
        text: '+7(705)111-11-11',
        selection: TextSelection.collapsed(offset: 7),
      ),
      const TextEditingValue(
        text: '+7(705111-11-11',
        selection: TextSelection.collapsed(offset: 6),
      ),
    );
    expect(midText.text, '+7(701)111-11-1');
    expect(midText.selection.baseOffset, 5);
  });

  test('forward delete over a mask separator deletes the digit after it', () {
    final formatter = KzPhoneMaskFormatter();

    final result = formatter.formatEditUpdate(
      const TextEditingValue(
        text: '+7(705)111-11-11',
        selection: TextSelection.collapsed(offset: 6),
      ),
      const TextEditingValue(
        text: '+7(705111-11-11',
        selection: TextSelection.collapsed(offset: 6),
      ),
    );
    expect(result.text, '+7(705)111-11-1');
    expect(result.selection.baseOffset, 6);
  });

  test('masked input normalizes to E.164 without mask', () {
    expect(normalizeKzPhone('+7(705)111-11-11'), '+77051111111');
    expect(normalizeKzPhone('+7'), isNull);
    expect(normalizeKzPhone('+7(705)111'), isNull);
  });
}
