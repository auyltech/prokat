import 'package:flutter/material.dart';
import 'package:prokat/l10n/app_localizations.dart';

class ChatHeaderError extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;

  const ChatHeaderError({super.key, required this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final errorColor = theme.colorScheme.error;

    return Row(
      children: [
        // 1. Fallback Error Avatar
        CircleAvatar(
          radius: 22,
          backgroundColor: errorColor.withValues(alpha: 0.1),
          child: Icon(Icons.error_outline_rounded, color: errorColor, size: 22),
        ),

        const SizedBox(width: 12),

        // 2. Error Text Information
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.errorLoadingProfile,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.tapToRetry,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: errorColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // 3. Optional Inline Retry Button
        if (onRetry != null)
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            color: theme.colorScheme.onPrimary.withValues(alpha: 0.6),
            onPressed: onRetry,
          ),
      ],
    );
  }
}
