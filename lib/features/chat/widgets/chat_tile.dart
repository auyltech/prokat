import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prokat/features/chat/state/chat_model.dart';

class ChatTile extends StatelessWidget {
  final ChatModel chat;
  final String currentUserId;
  final VoidCallback onTap;

  const ChatTile({
    super.key,
    required this.chat,
    required this.onTap,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarUrl = chat.displayImageUrl(currentUserId: currentUserId);

    final title = chat.displayTitle(currentUserId);

    final preview = chat.lastMessage?.content ?? 'No messages yet';

    final timestamp = _formatTimestamp(
      chat.lastMessage?.createdAt ?? chat.updatedAt,
    );

    final unreadCount = 2;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 28,
        backgroundImage: (avatarUrl ?? '').isNotEmpty
            ? NetworkImage(avatarUrl!)
            : null,
        child: (avatarUrl ?? '').isEmpty
            ? Text(
                title.isNotEmpty ? title[0].toUpperCase() : 'C',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(timestamp, style: theme.textTheme.labelSmall),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            preview,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
            ),
          ),
          if ((chat.bookingId ?? '').isNotEmpty ||
              (chat.requestId ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Wrap(
                spacing: 6,
                children: [
                  if ((chat.bookingId ?? '').isNotEmpty)
                    _ContextBadge(text: 'Booking linked'),
                  if ((chat.requestId ?? '').isNotEmpty)
                    _ContextBadge(text: 'Request linked'),
                ],
              ),
            ),
        ],
      ),
      trailing: unreadCount > 0
          ? Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${unreadCount}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }

  String _formatTimestamp(DateTime? dateTime) {
    if (dateTime == null) {
      return '';
    }

    final now = DateTime.now();
    if (now.difference(dateTime).inDays == 0) {
      return DateFormat.Hm().format(dateTime);
    }

    if (now.difference(dateTime).inDays < 7) {
      return DateFormat.E().format(dateTime);
    }

    return DateFormat('dd MMM').format(dateTime);
  }
}

class _ContextBadge extends StatelessWidget {
  final String text;

  const _ContextBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
