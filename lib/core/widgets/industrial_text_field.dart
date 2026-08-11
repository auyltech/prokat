import 'package:flutter/material.dart';

class IndustrialTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  final TextInputType keyboardType;

  /// 🔥 ADD THIS
  final Function(String)? onChanged;

  const IndustrialTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: theme.textTheme.labelMedium,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: theme.textTheme.labelMedium,
          hintText: hint,
          hintStyle: theme.textTheme.labelMedium?.copyWith(
            color: theme.textTheme.labelMedium?.color,
          ),
          prefixIcon: Icon(icon, color: theme.colorScheme.primary, size: 24),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          floatingLabelStyle: TextStyle(color: theme.colorScheme.primary),
        ),
      ),
    );
  }
}
