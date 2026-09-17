import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';

class AuthTextField extends StatefulWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final bool isPassword;
  final TextInputType? keyboardType;

  const AuthTextField({
    super.key,
    required this.label,
    required this.icon,
    required this.controller,
    this.isPassword = false,
    this.keyboardType,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    return TextField(
      controller: widget.controller,
      obscureText: widget.isPassword ? _obscureText : false,
      keyboardType: widget.keyboardType,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: onSurface,
        fontSize: 16,
      ),
      cursorColor: primary,
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: theme.textTheme.bodyMedium?.copyWith(
          color: onSurface.withValues(alpha: 0.6),
        ),

        prefixIcon: Icon(
          widget.icon,
          size: 20,
          color: onSurface.withValues(alpha: 0.6),
        ),

        /// Password toggle
        suffixIcon: widget.isPassword
            ? AppIconButton(
                icon: _obscureText ? Icons.visibility_off : Icons.visibility,
                onTap: () => setState(() => _obscureText = !_obscureText),
              )
            : null,

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

        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 16,
        ),
      ),
    );
  }
}
