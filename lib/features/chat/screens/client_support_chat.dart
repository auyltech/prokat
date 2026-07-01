import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/chat/state/chat_model.dart';
import 'package:prokat/features/chat/state/chat_provider.dart';
import 'package:prokat/features/chat/state/chat_status.dart';
import 'package:prokat/features/chat/widgets/message_bubble.dart';
import 'package:prokat/features/chat/widgets/send_message_form.dart';

class ClientSupportChat extends ConsumerStatefulWidget {
  const ClientSupportChat({super.key});

  @override
  ConsumerState<ClientSupportChat> createState() => _ClientSupportChatState();
}

class _ClientSupportChatState extends ConsumerState<ClientSupportChat> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      await ref.read(chatProvider.notifier).openChatById("support");
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Get current User
    final authState = ref.watch(authProvider);
    final currentUserId = authState.session?.user?.id ?? "";

    final chatState = ref.watch(chatProvider);

    final currentChat = chatState.conversations
        .where((item) => item.type == ChatType.support)
        .firstOrNull;

    final messages = chatState.messages
        .where((item) => item.chatId == (currentChat?.id ?? "support"))
        .toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {},
        child: SafeArea(
          child: Stack(
            children: [
              Text("Contact support"),
              // Main Content
              ListView.separated(
                reverse: false,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 12.0,
                ),
                separatorBuilder: (context, index) => SizedBox(height: 4),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  // 2. Invert the index so oldest messages (index 0 in data) render at the top
                  final invertedIndex = messages.length - 1 - index;
                  final message = messages[invertedIndex];
                  final isMe =
                      message.senderId == currentUserId ||
                      message.senderId == 'me';

                  return MessageBubble(
                    message: message,
                    isMe: isMe,
                    mode: "client",
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SendMessageForm(
        chatStatus: ChatStatus.unknown,
        type: ChatType.support,
        mode: AppMode.clientMode,
      ),
    );
  }
}
