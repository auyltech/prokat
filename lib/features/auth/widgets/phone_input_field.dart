import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:prokat/l10n/app_localizations.dart';

class PhoneInputField extends StatefulWidget {
  final TextEditingController controller;
  final String? label;

  const PhoneInputField({super.key, required this.controller, this.label});

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  late final MaskTextInputFormatter _phoneMask;

  @override
  void initState() {
    super.initState();
    _phoneMask = MaskTextInputFormatter(
      mask: '(###) ###-##-##',
      filter: {"#": RegExp(r'[0-9]')},
      type: MaskAutoCompletionType.lazy,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    return TextField(
      controller: widget.controller,
      keyboardType: TextInputType.phone,
      inputFormatters: [_phoneMask],
      style: theme.textTheme.bodyMedium?.copyWith(
        color: onSurface,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: widget.label ?? AppLocalizations.of(context)?.phoneNumber,
        prefixIconConstraints: const BoxConstraints(minWidth: 105),
        labelStyle: theme.textTheme.bodyMedium?.copyWith(
          color: onSurface.withValues(alpha: 0.6),
        ),
        // Static Prefix for KZ
        prefixIcon: Container(
          width: 105,
          padding: const EdgeInsets.only(left: 16, right: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("🇰🇿", style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                "+7",
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: onSurface,
                ),
              ),
            ],
          ),
        ),
        filled: true,
        fillColor: onSurface.withValues(alpha: 0.04),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      ),
    );
  }
}
