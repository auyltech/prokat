import 'package:flutter/material.dart';
import 'package:prokat/features/notifications/models/app_notification.dart';
import 'package:prokat/l10n/app_localizations.dart';

class NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const NotificationTile({
    super.key,
    required this.notification,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final languageCode = Localizations.localeOf(context).languageCode;
    final title = notification.localizedTitle(languageCode);
    final body = notification.localizedBody(languageCode);
    final isUnread = notification.isUnread;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        backgroundColor: isUnread
            ? theme.colorScheme.primary.withValues(alpha: 0.12)
            : theme.colorScheme.surfaceContainerHighest,
        foregroundColor: isUnread
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface,
        child: Icon(
          isUnread ? Icons.notifications_active : Icons.notifications,
        ),
      ),
      title: Text(
        title.isNotEmpty ? title : l10n.notification,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
      subtitle: Text(
        body,
        maxLines: 5,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: onDelete == null
          ? null
          : IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.delete,
            ),
    );
  }
}
