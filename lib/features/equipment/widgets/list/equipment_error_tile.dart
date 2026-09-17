import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/ui_kit/controls/buttons/app_elevated_button.dart';
import 'package:prokat/l10n/app_localizations.dart';

class EquipmentErrorTile extends StatelessWidget {
  final VoidCallback onRetry;
  final String? errorMessage;

  const EquipmentErrorTile({
    super.key,
    required this.onRetry,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: theme.colorScheme.error,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.couldNotLoadEquipment,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            errorMessage ?? l10n.loadEquipmentErrorHint,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onErrorContainer.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          AppElevatedButton.destructive(
            title: l10n.retryNow,
            onTap: onRetry,
            prefix: const Icon(Icons.refresh_rounded),
            isExpanded: false,
          ),
        ],
      ),
    );
  }
}
