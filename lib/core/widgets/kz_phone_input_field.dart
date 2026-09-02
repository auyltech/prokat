import 'package:flutter/material.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/utils/kz_phone_mask.dart';
import 'package:prokat/core/widgets/input_field.dart';
import 'package:prokat/l10n/app_localizations.dart';

class KzPhoneInputField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String? helperText;
  final IconData? icon;
  final bool readOnly;

  const KzPhoneInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.helperText,
    this.icon,
    this.readOnly = false,
  });

  @override
  State<KzPhoneInputField> createState() => _KzPhoneInputFieldState();
}

class _KzPhoneInputFieldState extends State<KzPhoneInputField> {
  final _formatter = KzPhoneMaskFormatter();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_restorePrefixIfCleared);
    _restorePrefixIfCleared();
  }

  @override
  void didUpdateWidget(KzPhoneInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_restorePrefixIfCleared);
    widget.controller.addListener(_restorePrefixIfCleared);
    _restorePrefixIfCleared();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_restorePrefixIfCleared);
    super.dispose();
  }

  void _restorePrefixIfCleared() {
    if (widget.controller.text.isNotEmpty) return;
    widget.controller.value = kzPhoneEditingValue(null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return InputField(
      controller: widget.controller,
      label: widget.label,
      hint: widget.hint,
      icon: widget.icon,
      helperText: widget.helperText,
      readOnly: widget.readOnly,
      keyboardType: TextInputType.phone,
      inputFormatters: [_formatter],
      validator: (value) {
        if (normalizeKzPhone(value) == null) {
          return l10n.enterValidPhoneNumber;
        }
        return null;
      },
    );
  }
}
