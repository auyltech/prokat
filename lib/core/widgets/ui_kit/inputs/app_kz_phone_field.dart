import 'package:flutter/material.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/utils/kz_phone_mask.dart';
import 'package:prokat/core/widgets/ui_kit/inputs/app_text_field.dart';
import 'package:prokat/l10n/app_localizations.dart';

class AppKzPhoneField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String? helperText;
  final bool readOnly;
  final String? Function(String?)? validator;

  const AppKzPhoneField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.helperText,
    this.readOnly = false,
    this.validator,
  });

  @override
  State<AppKzPhoneField> createState() => _AppKzPhoneFieldState();
}

class _AppKzPhoneFieldState extends State<AppKzPhoneField> {
  final _formatter = KzPhoneMaskFormatter();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_restorePrefixIfCleared);
    _restorePrefixIfCleared();
  }

  @override
  void didUpdateWidget(covariant AppKzPhoneField oldWidget) {
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

    return AppTextField(
      controller: widget.controller,
      label: widget.label,
      hint: widget.hint,
      readOnly: widget.readOnly,
      keyboardType: TextInputType.phone,
      inputFormatters: [_formatter],
      validator:
          widget.validator ??
          (value) {
            if (normalizeKzPhone(value) == null) {
              return l10n.enterValidPhoneNumber;
            }
            return null;
          },
    );
  }
}
