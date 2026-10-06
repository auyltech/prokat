import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/chat/providers/current_chat_provider.dart';
import 'package:prokat/features/user_safety/models/report_target.dart';
import 'package:prokat/features/user_safety/widgets/ugc_more_button.dart';
import 'package:prokat/l10n/app_localizations.dart';

/// ⋮ in the open direct chat app bar. Counterpart comes from server `blockState`.
class ChatSafetyMenuButton extends ConsumerWidget {
  const ChatSafetyMenuButton({
    super.key,
    required this.chatId,
    required this.currentUserId,
  });

  final String chatId;
  final String currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chat = ref.watch(currentChatProvider(chatId)).valueOrNull;
    final blockState = chat?.blockState;
    if (chat == null || chat.type == ChatType.support || blockState == null) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    return UgcMoreButton(
      counterpartUserId: blockState.counterpartUserId,
      counterpartName: chat.displayTitle(
        currentUserId,
        ownerFallback: l10n.nameNotSpecified,
        clientFallback: l10n.nameNotSpecified,
      ),
      reportTarget: ReportTarget(ReportTargetType.chat, chat.id),
      chatId: chat.id,
      isBlockedByMe: blockState.isBlockedByMe,
    );
  }
}
