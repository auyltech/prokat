import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/chat/providers/current_chat_provider.dart';
import 'package:prokat/features/chat/widgets/chat_header_error.dart';
import 'package:prokat/features/chat/widgets/chat_header_skeleton.dart';
import 'package:prokat/features/chat/widgets/user_avatar.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/l10n/app_localizations.dart';

class ChatHeaderTile extends ConsumerStatefulWidget {
  final String chatId;
  final String currentUserId;

  const ChatHeaderTile({
    super.key,
    required this.chatId,
    required this.currentUserId,
  });

  @override
  ConsumerState<ChatHeaderTile> createState() => _ChatHeaderTileState();
}

class _ChatHeaderTileState extends ConsumerState<ChatHeaderTile> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final flow = ProkatFlowPalette.of(context);

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
        final showsOwner = chat.client?.id == widget.currentUserId;
        final availability = showsOwner && chat.owner?.onlineStatus != null;

        if (chat.type == ChatType.support) {
          return Text(
            l10n.support,
            style: AppFonts.body16SemiBold(context)
                .copyWith(color: context.colors.appBar.content),
          );
        }

        return Row(
          children: [
            UserAvatar(radius: 20, avatarUrl: avatarUrl, fullName: title),

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
                      fontSize: 15,
                      color: title == l10n.nameNotSpecified
                          ? flow.secondary
                          : flow.title,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    availability
                        ? '${chat.owner!.isAccountOnline ? '● ' : ''}${chat.owner!.isAccountOnline ? l10n.accountOnline : l10n.accountOffline}'
                        : showsOwner
                        ? l10n.owner
                        : l10n.clientRole,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: availability && chat.owner!.isAccountOnline
                          ? flow.success
                          : flow.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
