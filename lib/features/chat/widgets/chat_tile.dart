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

    // Using a hardcoded unread count as per your snippet
    const unreadCount = 2;

    return InkWell(
      onTap: onTap,
      child: Padding(
        // Vertical padding provides breathing room between tiles,
        // horizontal padding is set to 16 for standard alignment
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // 1. Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: theme.colorScheme.primaryContainer,
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
            const SizedBox(width: 16),

            // 2. Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Time under the message
                  Text(
                    timestamp,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.disabledColor,
                    ),
                  ),
                ],
              ),
            ),

            // 3. Unread Indicator
            if (unreadCount > 0)
              Container(
                height: 20,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$unreadCount',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
      ),
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
