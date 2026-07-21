import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/chat/models/chat_lookup.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/chat/providers/chat_providers.dart';
import 'package:prokat/features/chat/providers/current_chat_provider.dart';
import 'package:prokat/features/chat/state/chat_status_detail.dart';
import 'package:prokat/features/chat/widgets/message_bubble.dart';
import 'package:prokat/features/chat/widgets/send_message_form.dart';

class ClientSupportChat extends ConsumerStatefulWidget {
  const ClientSupportChat({super.key});

  @override
  ConsumerState<ClientSupportChat> createState() => _ClientSupportChatState();
}

class _ClientSupportChatState extends ConsumerState<ClientSupportChat> {
  static const _lookup = ChatLookup.byType(ChatType.support);

  Future<void> _refresh() async {
    // 1. Refresh chat resolver identity
    final resolved = await ref.refresh(chatResolverProvider(_lookup).future);

    // SAFETY GUARD: Prevent processing background updates if the user navigated away
    if (!mounted) return;

    // 2. Fetch the corresponding items over asynchronous wait loops
    await Future.wait([
      ref.read(currentChatProvider(resolved.id).notifier).refresh(),
      ref.read(chatMessagesProvider(resolved.id).notifier).refresh(),
    ]);
  }

  Widget _centerScrollable(BuildContext context, Widget child) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Center(child: child),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final currentUserId = authState.session?.user?.id ?? "";
    final resolvedChat = ref.watch(chatResolverProvider(_lookup));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SafeArea(
          child: resolvedChat.when(
            loading: () => _centerScrollable(
              context,
              const CircularProgressIndicator.adaptive(),
            ),
            error: (error, _) =>
                _centerScrollable(context, Text(error.toString())),
            data: (resolved) {
              final chat = ref.watch(currentChatProvider(resolved.id));
              final messages =
                  ref.watch(chatMessagesProvider(resolved.id)).value?.items ??
                  [];

              return Column(
                children: [
                  Text(resolvedChat.valueOrNull?.type.name ?? ""),

                  // FIX: Wrap inside Expanded to resolve nested scroll-pass layout constraints
                  Expanded(
                    child: chat.when(
                      loading: () => _centerScrollable(
                        context,
                        const CircularProgressIndicator.adaptive(),
                      ),
                      error: (error, _) =>
                          _centerScrollable(context, Text(error.toString())),
                      data: (chatData) {
                        return ListView.separated(
                          // Explicit physics configuration prevents scrolling layout collisions
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          separatorBuilder: (_, _) => const SizedBox(height: 4),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final invertedIndex = messages.length - 1 - index;
                            final message = messages[invertedIndex];

                            return MessageBubble(
                              message: message,
                              isMe: message.senderId == currentUserId,
                              mode: AppMode.clientMode,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
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
