import 'package:flutter/services.dart';

/// Keeps only digits and rejects a value above [max] instead of clipping it.
class MaxIntInputFormatter extends TextInputFormatter {
  const MaxIntInputFormatter(this.max);

  final int max;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    final parsed = int.tryParse(text);
    if (parsed == null) return oldValue;
    if (parsed > max) return oldValue;

    return newValue;
  }
}
