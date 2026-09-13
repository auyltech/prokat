import 'package:flutter/material.dart';
import 'package:prokat/l10n/app_localizations.dart';

class AdminCommentBlock extends StatelessWidget {
  final String? comment;

  const AdminCommentBlock({super.key, required this.comment});

  @override
  Widget build(BuildContext context) {
    final text = (comment ?? '').trim();
    if (text.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.adminComment,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.outline.withValues(alpha: 0.35)),
          ),
          child: Text(text, style: theme.textTheme.bodyMedium),
        ),
      ],
    );
  }
}
