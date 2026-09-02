import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/chat/providers/current_chat_provider.dart';
import 'package:prokat/features/chat/widgets/chat_header_error.dart';
import 'package:prokat/features/chat/widgets/chat_header_skeleton.dart';
import 'package:prokat/features/chat/widgets/user_avatar.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final bool isValidId = widget.chatId.trim().isNotEmpty;

    if (!isValidId) {
      return const SizedBox.shrink(); // Early exit for invalid IDs
    }

    final chatAsync = ref.watch(currentChatProvider(widget.chatId));

    return chatAsync.when(
      loading: () => const ChatHeaderSkeleton(),
      error: (error, stack) => ChatHeaderError(
        error: error,
        onRetry: () {
          // Force riverpod to re-fetch the provider data
          ref.invalidate(currentChatProvider(widget.chatId));
        },
      ),
      data: (chat) {
        if (chat == null) return Text(widget.chatId);
        // if (chat == null) return const SizedBox.shrink();

        final avatarUrl = chat.displayImageUrl(
          currentUserId: widget.currentUserId,
        );
        final title = chat.displayTitle(
          widget.currentUserId,
          ownerFallback: l10n.nameNotSpecified,
          clientFallback: l10n.nameNotSpecified,
        );
        final lastMessageAt = chat.lastMessage?.createdAt;

        if (chat.type == ChatType.support) {
          return Text(
            l10n.support,
            style: const TextStyle(color: Colors.black),
          );
        }

        return GestureDetector(
          onTap: () {
            unawaited(
              context.push(
                '${widget.isOwner ? AppRoutes.ownerChatList : AppRoutes.clientChatList}/direct/${widget.chatId}/info',
              ),
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
                        fontWeight: title == l10n.nameNotSpecified
                            ? FontWeight.w400
                            : FontWeight.bold,
                        color: title == l10n.nameNotSpecified
                            ? theme.colorScheme.onSurface.withValues(
                                alpha: 0.55,
                              )
                            : null,
                      ),
                    ),
                    if (lastMessageAt != null)
                      Text(
                        formatDateTime(
                          lastMessageAt,
                          lastMessageAt,
                          locale: l10n.localeName,
                        ),
                        style: theme.textTheme.labelSmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
