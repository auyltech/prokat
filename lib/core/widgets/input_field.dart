import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prokat/l10n/app_localizations.dart';

class InputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final bool isNumeric;
  final bool isLast;
  final bool isRequired; // Added property
  final String? suffixText;
  final String? Function(String?)? validator;
  final IconData? icon;
  final Color? iconBgColor;
  final Color? iconColor;
  final VoidCallback? onChanged;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? errorText;
  final String? helperText;
  final String? requiredMessage;

  const InputField({
    super.key,
    required this.label,
    required this.controller,
    required this.hint,
    this.isNumeric = false,
    this.isLast = false,
    this.isRequired = false, // Defaulted to false
    this.requiredMessage,
    this.validator,
    this.suffixText,
    this.icon,
    this.iconBgColor,
    this.iconColor,
    this.onChanged,
    this.keyboardType,
    this.inputFormatters,
    this.errorText,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: helperText != null
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Container(
            width: 45,
            height: 50,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 25),
          ),

          const SizedBox(width: 12),
        ],

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top row: Label and required indicator
              Text.rich(
                TextSpan(
                  text: label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  children: [
                    if (isRequired)
                      TextSpan(
                        text: ' *',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                  ],
                ),
              ),

              // Bottom row: Input field and suffix text
              Row(
                children: [
                  Expanded(
                    // Fixes layout crash by constraining the TextFormField width
                    child: TextFormField(
                      controller: controller,
                      validator: (value) {
                        final text = value?.trim() ?? '';

                        if (isRequired && text.isEmpty) {
                          return requiredMessage ??
                              AppLocalizations.of(context)?.fieldRequired;
                        }

                        return validator?.call(value);
                      },
                      onChanged: (_) => onChanged?.call(),
                      keyboardType: isNumeric
                          ? TextInputType.number
                          : keyboardType,
                      inputFormatters: inputFormatters,
                      textInputAction: isLast
                          ? TextInputAction.done
                          : TextInputAction.next,
                      cursorColor: colorScheme.primary,
                      style: theme.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: hint,
                        hintStyle: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w400,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.only(
                          top: 4,
                          bottom: 4,
                        ),
                        border: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        errorStyle: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  if (suffixText != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 12.0),
                      child: Text(
                        suffixText!,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),

              if (helperText != null) ...[
                const SizedBox(height: 4),
                Text(
                  helperText!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],

              if (errorText != null) ...[
                const SizedBox(height: 6),
                Text(
                  errorText!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
