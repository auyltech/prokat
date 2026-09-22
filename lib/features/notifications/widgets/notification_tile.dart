import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prokat/core/media/media_image_provider.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/notifications/models/app_notification.dart';
import 'package:prokat/l10n/app_localizations.dart';

class NotificationTile extends ConsumerWidget {
  final AppNotification notification;
  final int? unreadCount;
  final bool chatStyle;
  final String? senderName;
  final String? senderImageUrl;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const NotificationTile({
    super.key,
    required this.notification,
    this.onTap,
    this.unreadCount,
    this.chatStyle = false,
    this.senderName,
    this.senderImageUrl,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final languageCode = Localizations.localeOf(context).languageCode;
    final title = notification.localizedTitle(languageCode);
    final body = notification.localizedBody(languageCode);
    final messageCount = unreadCount ?? 0;
    final isUnread = unreadCount == null
        ? notification.isUnread
        : messageCount > 0;
    final resolvedName = senderName?.trim() ?? '';
    final titleText = chatStyle && resolvedName.isNotEmpty
        ? l10n.newMessageFrom(resolvedName)
        : (title.isNotEmpty ? title : l10n.notification);

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: chatStyle
          ? _SenderAvatar(
              name: resolvedName,
              imageUrl: senderImageUrl,
              isUnread: isUnread,
            )
          : CircleAvatar(
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
        titleText,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(body, maxLines: 2, overflow: TextOverflow.ellipsis),
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
      trailing: _Trailing(
        messageCount: chatStyle ? messageCount : 0,
        onDelete: onDelete,
        deleteTooltip: l10n.delete,
      ),
    );
  }
}

class _SenderAvatar extends ConsumerWidget {
  final String name;
  final String? imageUrl;
  final bool isUnread;

  const _SenderAvatar({
    required this.name,
    required this.imageUrl,
    required this.isUnread,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final provider = mediaImageProvider(ref, imageUrl);
    final initial = name.isEmpty ? '' : name[0].toUpperCase();

    return CircleAvatar(
      radius: 22,
      backgroundColor: isUnread
          ? theme.colorScheme.primary.withValues(alpha: 0.12)
          : theme.colorScheme.surfaceContainerHighest,
      foregroundColor: isUnread
          ? theme.colorScheme.primary
          : theme.colorScheme.onSurface,
      backgroundImage: provider,
      onBackgroundImageError: provider == null
          ? null
          : ignoreMediaImageLoadError,
      child: provider != null
          ? null
          : initial.isEmpty
          ? const Icon(Icons.person_outline)
          : Text(
              initial,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}

class _Trailing extends StatelessWidget {
  final int messageCount;
  final VoidCallback? onDelete;
  final String deleteTooltip;

  const _Trailing({
    required this.messageCount,
    required this.onDelete,
    required this.deleteTooltip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showCount = messageCount > 0;
    if (!showCount && onDelete == null) return const SizedBox.shrink();

    final label = messageCount > 99 ? '99+' : '$messageCount';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showCount)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        if (onDelete != null)
          AppIconButton(
            onTap: onDelete,
            icon: Icons.delete_outline,
            tone: AppIconButtonTone.destructive,
            tooltip: deleteTooltip,
          ),
      ],
    );
  }
}
