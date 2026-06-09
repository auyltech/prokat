import 'package:flutter/material.dart';

class InputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final bool isNumeric;
  final bool isLast;
  final String? suffixText;
  final String? Function(String?)? validator;
  final IconData? icon;
  final VoidCallback? onChanged;
  final TextInputType? keyboardType;

  const InputField({
    super.key,
    required this.label,
    required this.controller,
    required this.hint,
    this.isNumeric = false,
    this.isLast = false,
    this.validator,
    this.suffixText,
    this.icon,
    this.onChanged,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        onChanged: (_) => onChanged != null ? onChanged!() : null,
        keyboardType: keyboardType,
        // isNumeric
        //     ? const TextInputType.numberWithOptions(decimal: true)
        //     : TextInputType.text,
        cursorColor: colorScheme.primary,
        style: theme.textTheme.bodyMedium,
        decoration: InputDecoration(
          prefixIcon: icon != null
              ? Icon(icon, color: theme.colorScheme.primary, size: 32)
              : null,
          labelText: label,
          hintText: hint,
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          border: InputBorder.none,
          errorStyle: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.error,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );

    // if (suffixText != null)
    //   Container(
    //     margin: const EdgeInsets.only(left: 8),
    //     padding: const EdgeInsets.symmetric(
    //       horizontal: 8,
    //       vertical: 4,
    //     ),
    //     decoration: BoxDecoration(
    //       color: colorScheme.primary.withValues(alpha: 0.1),
    //       borderRadius: BorderRadius.circular(6),
    //     ),
    //     child: Text(
    //       suffixText!,
    //       style: theme.textTheme.labelSmall?.copyWith(
    //         color: colorScheme.primary,
    //         fontWeight: FontWeight.bold,
    //       ),
    //     ),
    //   ),
  }
}
