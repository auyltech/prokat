import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/chat/models/chat_lookup.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/chat/providers/chat_providers.dart';
import 'package:prokat/features/chat/providers/current_chat_provider.dart';
import 'package:prokat/features/chat/state/chat_status_detail.dart';
import 'package:prokat/features/chat/widgets/chat_message_list.dart';
import 'package:prokat/features/chat/widgets/send_message_form.dart';

class ClientSupportChat extends ConsumerStatefulWidget {
  const ClientSupportChat({super.key});

  @override
  ConsumerState<ClientSupportChat> createState() => _ClientSupportChatState();
}

class _ClientSupportChatState extends ConsumerState<ClientSupportChat> {
  static const _lookup = ChatLookup.byType(ChatType.support);

  Widget _center(Widget child) {
    return Center(child: child);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final currentUserId = authState.session?.user?.id ?? "";
    final resolvedChat = ref.watch(chatResolverProvider(_lookup));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: resolvedChat.when(
          loading: () => _center(const CircularProgressIndicator.adaptive()),
          error: (error, _) => _center(Text(error.toString())),
          data: (resolved) {
            return Column(
              children: [
                Text(resolvedChat.valueOrNull?.type.name ?? ""),
                Expanded(
                  child: ChatMessageList(
                    chatId: resolved.id,
                    currentUserId: currentUserId,
                    mode: AppMode.clientMode,
                    currentChat: ref
                        .watch(currentChatProvider(resolved.id))
                        .valueOrNull,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: resolvedChat.maybeWhen(
        data: (chat) => SendMessageForm(
          chatId: chat.id,
          chatStatus: ChatStatusDetail.unknown,
          type: chat.type,
          mode: AppMode.clientMode,
        ),
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }
}
