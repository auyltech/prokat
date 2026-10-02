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
    final separatorDelete = _deleteDigitAcrossSeparator(oldValue, newValue);
    if (separatorDelete != null) return separatorDelete;

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

  /// Deleting only mask chars (`(`, `)`, `-`) would be re-added by the mask,
  /// so drop the adjacent digit instead: before the gap on backspace,
  /// after it on forward delete.
  TextEditingValue? _deleteDigitAcrossSeparator(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final oldText = oldValue.text;
    final newText = newValue.text;
    final removed = oldText.length - newText.length;
    if (removed <= 0 ||
        !oldValue.selection.isValid ||
        !newValue.selection.isCollapsed) {
      return null;
    }

    final start = newValue.selection.start;
    final end = start + removed;
    if (start < 0 || end > oldText.length) return null;
    if (oldText.substring(0, start) != newText.substring(0, start) ||
        oldText.substring(end) != newText.substring(start)) {
      return null;
    }
    if (oldText.substring(start, end).contains(_digit)) return null;

    final national = nationalKzPhoneDigits(oldText);
    final digitsBefore = nationalKzPhoneDigits(oldText.substring(0, start))
        .length;
    final isBackspace = oldValue.selection.end == end;
    final index = isBackspace ? digitsBefore - 1 : digitsBefore;
    if (index < 0 || index >= national.length) return null;

    final formatted = formatKzPhoneMask(
      national.replaceRange(index, index + 1, ''),
    );
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: kzPhoneMaskCursorOffset(formatted, index),
      ),
    );
  }
}
