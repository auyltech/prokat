import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class PhoneInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const PhoneInputField({
    super.key,
    required this.controller,
    this.label = "Phone Number",
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    // Kazakhstan mask: (7xx) xxx-xx-xx
    final phoneMask = MaskTextInputFormatter(
      mask: '(###) ###-##-##',
      filter: {"#": RegExp(r'[0-9]')},
      type: MaskAutoCompletionType.lazy,
    );

    return TextField(
      controller: controller,
      keyboardType: TextInputType.phone,
      inputFormatters: [phoneMask],
      style: theme.textTheme.bodyMedium?.copyWith(
        color: onSurface,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: theme.textTheme.bodyMedium?.copyWith(
          color: onSurface.withValues(alpha: 0.6),
        ),
        // Static Prefix for KZ
        prefixIcon: Container(
          width: 85,
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
