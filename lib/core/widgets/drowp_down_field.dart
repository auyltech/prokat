import 'package:flutter/material.dart';

class DropDownfield<T> extends StatelessWidget {
  final String label;
  final T? value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;
  final IconData? icon;

  const DropDownfield({
    super.key,
    required this.label,
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
    this.validator,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      validator: validator,
      icon: Icon(
        Icons.keyboard_arrow_down,
        color: colorScheme.onSurface.withValues(alpha: 0.6),
      ),
      // Mirroring the exact Container decoration style from your InputField
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 12,
        ),
        filled: true,
        fillColor: theme.colorScheme.surfaceBright,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        prefixIcon: icon != null
            ? Padding(
                padding: const EdgeInsets.only(right: 16.0, left: 4.0),
                child: Icon(icon, color: colorScheme.primary, size: 24),
              )
            : null,
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        // Embedding the upper structural layout using structural label widgets
        label: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        hintText: hint,
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface.withValues(alpha: 0.3),
        ),
        errorStyle: theme.textTheme.labelSmall?.copyWith(
          color: colorScheme.error,
          fontWeight: FontWeight.bold,
        ),
      ),
      // Dropdown style customization to match the overall design feel
      dropdownColor: theme.colorScheme.surfaceBright,
      style: theme.textTheme.bodyMedium,
      isExpanded: true,
    );
  }
}
