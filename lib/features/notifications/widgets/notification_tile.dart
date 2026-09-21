import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/notifications/models/app_notification.dart';
import 'package:prokat/l10n/app_localizations.dart';

class NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final int? unreadCount;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const NotificationTile({
    super.key,
    required this.notification,
    this.onTap,
    this.unreadCount,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final languageCode = Localizations.localeOf(context).languageCode;
    final title = notification.localizedTitle(languageCode);
    final body = notification.localizedBody(languageCode);
    final isUnread = unreadCount == null
        ? notification.isUnread
        : unreadCount! > 0;

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
        child: Badge(
          isLabelVisible: (unreadCount ?? 0) > 0,
          child: Icon(
            unreadCount != null
                ? Icons.chat_bubble_outline
                : isUnread
                ? Icons.notifications_active
                : Icons.notifications,
          ),
        ),
      ),
      title: Text(
        title.isNotEmpty ? title : l10n.notification,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(body, maxLines: 5, overflow: TextOverflow.ellipsis),
          if (notification.createdAt != null) ...[
            const SizedBox(height: 6),
            Text(
              DateFormat(
                'd MMM, HH:mm',
                languageCode,
              ).format(notification.createdAt!.toLocal()),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
      trailing: onDelete == null
          ? null
          : AppIconButton(
              onTap: onDelete,
              icon: Icons.delete_outline,
              tone: AppIconButtonTone.destructive,
              tooltip: l10n.delete,
            ),
    );
  }
}
