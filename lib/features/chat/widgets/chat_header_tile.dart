import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/chat/state/chat_provider.dart';
import 'package:prokat/features/chat/widgets/user_avatar.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:go_router/go_router.dart';

class ChatHeaderTile extends ConsumerStatefulWidget {
  final String currentUserId;
  final bool isOwner;

  const ChatHeaderTile({
    super.key,
    required this.currentUserId,
    required this.isOwner,
  });

  @override
  ConsumerState<ChatHeaderTile> createState() => _ChatHeaderTileState();
}

class _ChatHeaderTileState extends ConsumerState<ChatHeaderTile> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final chatState = ref.watch(chatProvider);
    final currentChat = chatState.currentChat;
    final messages = chatState.messages;

    final title = currentChat?.displayTitle(widget.currentUserId) ?? 'Chat';
    final avatarUrl = currentChat?.displayImageUrl(
      currentUserId: widget.currentUserId,
    );

    final lastMessageAt = messages.isNotEmpty ? messages[0].createdAt : null;

    return GestureDetector(
      onTap: () {
        context.push(
          '${widget.isOwner ? AppRoutes.ownerChatList : AppRoutes.clientChatList}/${currentChat?.id}/info',
        );
      },
      child: Row(
        children: [
          UserAvatar(radius: 22, avatarUrl: avatarUrl, fullName: title),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                if (lastMessageAt != null)
                  Text(
                    formatDateTime(lastMessageAt, lastMessageAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
