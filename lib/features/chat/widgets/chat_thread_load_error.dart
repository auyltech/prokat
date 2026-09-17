import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/chat/utils/chat_error_utils.dart';
import 'package:prokat/l10n/app_localizations.dart';

class ChatThreadLoadError extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const ChatThreadLoadError({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: theme.colorScheme.error.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 16),
              Text(
                friendlyChatError(error, l10n),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              AppElevatedButton(
                title: l10n.retry,
                onTap: onRetry,
                isExpanded: false,
                prefix: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
