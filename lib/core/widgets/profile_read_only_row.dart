import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';

class ProfileReadOnlyRow extends StatelessWidget {
  final String label;
  final String? value;
  final String? helperText;

  const ProfileReadOnlyRow({
    super.key,
    required this.label,
    required this.value,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final display = (value ?? '').trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppDimens.s04$xs),
        Text(
          display.isEmpty ? '—' : display,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: display.isEmpty
                ? theme.colorScheme.onSurface.withValues(alpha: 0.45)
                : null,
          ),
        ),
        if (helperText != null && helperText!.trim().isNotEmpty) ...[
          const SizedBox(height: AppDimens.s04$xs),
          Text(
            helperText!,
            style: AppFonts.caption(context)
                .copyWith(color: context.colors.text.tertiary),
          ),
        ],
      ],
    );
  }
}
