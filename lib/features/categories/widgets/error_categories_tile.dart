import 'package:flutter/material.dart';

class ErrorCategoriesCard extends StatelessWidget {
  final VoidCallback? onRetry;

  const ErrorCategoriesCard({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // Uses the theme's error color but very subtly
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        // Row looks better for error states with action buttons
        children: [
          Icon(
            Icons.cloud_off_rounded,
            color: theme.colorScheme.error,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Couldn't load categories",
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
                Text(
                  "Please check your connection.",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer.withValues(
                      alpha: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (onRetry != null)
            IconButton(
              onPressed: onRetry,
              icon: Icon(Icons.refresh, color: theme.colorScheme.error),
            ),
        ],
      ),
    );
  }
}
