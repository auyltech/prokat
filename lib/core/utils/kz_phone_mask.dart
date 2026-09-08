import 'dart:math' as math;

import 'package:flutter/services.dart';

final _nonDigits = RegExp(r'\D');
final _digit = RegExp(r'\d');

/// National 10 digits from a typed, pasted, or stored Kazakhstan number.
///
/// `+7` / `+8` / leading `7`/`8` of an 11-digit value are treated as the
/// country code so a displayed `+7(705)111-11-11` yields `7051111111`.
String nationalKzPhoneDigits(String input) {
  final trimmed = input.trim();
  String digits;

  if (trimmed.startsWith('+7') || trimmed.startsWith('+8')) {
    digits = trimmed.substring(2).replaceAll(_nonDigits, '');
  } else {
    digits = trimmed.replaceAll(_nonDigits, '');
    if (digits.length >= 11 &&
        (digits.startsWith('7') || digits.startsWith('8'))) {
      digits = digits.substring(1);
    }
  }

  if (digits.length > 10) {
    return digits.substring(0, 10);
  }
  return digits;
}

/// Progressive mask: `+7`, `+7(705)`, `+7(705)111-11-11`.
String formatKzPhoneMask(String nationalDigits) {
  final d = nationalDigits.replaceAll(_nonDigits, '');
  final clipped = d.length > 10 ? d.substring(0, 10) : d;

  final buffer = StringBuffer('+7');
  if (clipped.isEmpty) return buffer.toString();

  buffer.write('(');
  buffer.write(clipped.substring(0, math.min(3, clipped.length)));
  if (clipped.length < 3) return buffer.toString();

  buffer.write(')');
  if (clipped.length == 3) return buffer.toString();

  buffer.write(clipped.substring(3, math.min(6, clipped.length)));
  if (clipped.length <= 6) return buffer.toString();

  buffer.write('-');
  buffer.write(clipped.substring(6, math.min(8, clipped.length)));
  if (clipped.length <= 8) return buffer.toString();

  buffer.write('-');
  buffer.write(clipped.substring(8));
  return buffer.toString();
}

String maskedKzPhone(String? raw) {
  return formatKzPhoneMask(nationalKzPhoneDigits(raw ?? ''));
}

TextEditingValue kzPhoneEditingValue(String? raw) {
  final masked = maskedKzPhone(raw);
  return TextEditingValue(
    text: masked,
    selection: TextSelection.collapsed(offset: masked.length),
  );
}

int kzPhoneMaskCursorOffset(String formatted, int nationalDigitsBeforeCursor) {
  if (nationalDigitsBeforeCursor <= 0) {
    return formatted.startsWith('+7') ? 2 : 0;
  }

  final start = formatted.startsWith('+7') ? 2 : 0;
  var seen = 0;
  for (var i = start; i < formatted.length; i++) {
    if (_digit.hasMatch(formatted[i])) {
      seen++;
      if (seen == nationalDigitsBeforeCursor) return i + 1;
    }
  }
  return formatted.length;
}

class KzPhoneMaskFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final national = nationalKzPhoneDigits(newValue.text);
    final formatted = formatKzPhoneMask(national);
    final cursor = newValue.selection.end.clamp(0, newValue.text.length);
    final atEnd = cursor >= newValue.text.length;
    final digitsBefore = nationalKzPhoneDigits(
      newValue.text.substring(0, cursor),
    ).length;
    final offset =
        (atEnd
                ? formatted.length
                : kzPhoneMaskCursorOffset(formatted, digitsBefore))
            .clamp(0, formatted.length);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}
