import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/chat/providers/chat_providers.dart';
import 'package:prokat/features/chat/widgets/user_avatar.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:go_router/go_router.dart';

class ChatHeaderTile extends ConsumerStatefulWidget {
  final String chatId;
  final String currentUserId;
  final bool isOwner;

  const ChatHeaderTile({
    super.key,
    required this.chatId,
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

    final chatAsync = ref.watch(chatProvider(widget.chatId));
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chatId));

    final chat = chatAsync.value;
    final messages = messagesAsync.value?.items ?? const [];

    final title = chat?.displayTitle(widget.currentUserId) ?? 'Chat';
    final avatarUrl = chat?.displayImageUrl(
      currentUserId: widget.currentUserId,
    );

    final lastMessageAt = messages.isNotEmpty ? messages[0].createdAt : null;

    return GestureDetector(
      onTap: () {
        context.push(
          '${widget.isOwner ? AppRoutes.ownerChatList : AppRoutes.clientChatList}/direct/${widget.chatId}/info',
        );
      },
      child: (chat?.type == ChatType.support)
          ? Text("Support")
          : Row(
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
                            color: theme.colorScheme.onPrimary.withValues(
                              alpha: 0.7,
                            ),
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
