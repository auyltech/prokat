import 'package:flutter/services.dart';

/// Longest everyday Kazakhstan plate with spaces, e.g. `01 ABC 1234`.
/// Formats differ (old / 2012 / legal entity), so we only cap length.
const kzPlateMaxLength = 12;

final _allowedPlateChar = RegExp(r'[A-Za-zА-Яа-яЁё0-9 ]');

String sanitizeKzPlate(String input) {
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    final ch = String.fromCharCode(rune);
    if (!_allowedPlateChar.hasMatch(ch)) continue;
    buffer.write(ch.toUpperCase());
    if (buffer.length >= kzPlateMaxLength) break;
  }
  return buffer.toString();
}

class KzPlateInputFormatter extends TextInputFormatter {
  const KzPlateInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final filtered = sanitizeKzPlate(newValue.text);
    final rawCursor = newValue.selection.baseOffset;
    var kept = 0;
    if (rawCursor > 0) {
      final limit = rawCursor.clamp(0, newValue.text.length);
      for (var i = 0; i < limit; i++) {
        if (_allowedPlateChar.hasMatch(newValue.text[i])) kept++;
      }
    }
    if (kept > filtered.length) kept = filtered.length;

    return TextEditingValue(
      text: filtered,
      selection: TextSelection.collapsed(offset: kept),
    );
  }
}
