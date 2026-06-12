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
      padding: const EdgeInsets.symmetric(
        vertical: 6,
        horizontal: 8,
      ), // Adjusted vertical padding
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        onChanged: (_) => onChanged != null ? onChanged!() : null,
        keyboardType: keyboardType,
        cursorColor: colorScheme.primary,
        style: theme.textTheme.bodyMedium,
        decoration: InputDecoration(
          prefixIcon: icon != null
              ? Icon(icon, color: theme.colorScheme.primary, size: 32)
              : null,

          // 1. Keep the label and style it with a smaller font weight
          labelText: label,
          labelStyle: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600, // Thinner visual weight
            color: colorScheme.onSurface.withValues(alpha: 0.8),
          ),

          // 2. Force the label to always stay pinned at the top
          floatingLabelBehavior: FloatingLabelBehavior.always,

          // 3. Your hint text can now display safely underneath it
          hintText: hint,
          hintStyle: theme.textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.8),
            fontWeight: FontWeight.w400,
          ),

          isDense: true,
          // 4. Added top content padding to prevent the hint text from colliding with the label
          contentPadding: const EdgeInsets.only(top: 14, bottom: 8),
          border: InputBorder.none,

          suffix: suffixText != null
              ? Padding(
                  // 1. Adds padding to the left (spacing from input text) and right (spacing from border)
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Text(
                    suffixText!,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : null,

          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.error, width: 1.0),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.error, width: 1.5),
          ),

          // 4. Native custom styling for the bottom-rendered message
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
    //     child: ,
    //   ),
  }
}
