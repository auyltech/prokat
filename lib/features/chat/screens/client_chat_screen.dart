import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/chat/state/chat_provider.dart';
import 'package:prokat/features/chat/widgets/booking_actions/client_chat_action_bar.dart';
import 'package:prokat/features/chat/widgets/message_bubble.dart';
import 'package:prokat/features/chat/widgets/booking_message_bubble.dart';
import 'package:prokat/features/chat/widgets/send_message_form.dart';

class ClientChatScreen extends ConsumerStatefulWidget {
  final String chatId;

  const ClientChatScreen({super.key, required this.chatId});

  @override
  ConsumerState<ClientChatScreen> createState() => _ClientChatScreenState();
}

class _ClientChatScreenState extends ConsumerState<ClientChatScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(chatProvider.notifier).openChatById(widget.chatId);
    });
  }

  @override
  void didUpdateWidget(covariant ClientChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chatId != widget.chatId) {
      Future.microtask(() {
        ref.read(chatProvider.notifier).openChatById(widget.chatId);
      });
    }
  }

  @override
  void dispose() {
    ref.read(chatProvider.notifier).leaveCurrentChat();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final chatState = ref.watch(chatProvider);
    final authState = ref.watch(authProvider);

    final messages = chatState.messages;

    final currentChat = chatState.currentChat;

    final currentUserId = authState.session?.user?.id ?? "";

    final title = currentChat?.displayTitle(currentUserId) ?? 'Chat';

    final avatarUrl = currentChat?.displayImageUrl(
      currentUserId: currentUserId,
    );

    final booking = currentChat?.booking;
    final request = currentChat?.request;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: theme.colorScheme.onPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: GestureDetector(
          onTap: () => context.push('${AppRoutes.chat}/${widget.chatId}/info'),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: (avatarUrl ?? '').isNotEmpty
                    ? NetworkImage(avatarUrl!)
                    : null,
                child: (avatarUrl ?? '').isEmpty
                    ? Text(title.isNotEmpty ? title[0].toUpperCase() : 'C')
                    : null,
              ),
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          if (chatState.isLoadingMessages)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (chatState.error != null && messages.isEmpty)
            Expanded(
              child: Center(
                child: Text(chatState.error ?? "Error Loading Messages"),
              ),
            )
          else
            // 1. Chat history area (Fills screen, scrollable, handles banner inside)
            Expanded(
              child: Container(
                color: theme.colorScheme.surface,
                child: ListView.builder(
                  reverse: false,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 12.0,
                  ),
                  itemCount: (booking != null || request != null)
                      ? messages.length + 1
                      : messages.length,
                  itemBuilder: (context, index) {
                    final hasBookingHeader = booking != null || request != null;

                    if (hasBookingHeader) {
                      if (index == 0) {
                        return BookingMessageBubble(
                          booking: booking as BookingModel,
                        );
                      }
                    }

                    // 1. Shift index by 1 if header is present
                    final messageIndex = hasBookingHeader ? index - 1 : index;

                    // 2. Invert the index so oldest messages (index 0 in data) render at the top
                    final invertedIndex = messages.length - 1 - messageIndex;

                    final message = messages[invertedIndex];
                    final isMe =
                        message.senderId == currentUserId ||
                        message.senderId == 'me';

                    return MessageBubble(message: message, isMe: isMe);
                  },
                ),
              ),
            ),

          if (booking != null)
            ClientChatActionBar(chatId: widget.chatId, booking: booking),

          // 2. Static input area perfectly pinned to the absolute viewport bottom
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border(
                // top: BorderSide(
                //   color: theme.dividerColor.withValues(alpha: 0.2),
                //   width: 1.0,
                // ),
              ),
            ),
            child: SafeArea(
              top: false,
              left: false,
              right: false,
              bottom:
                  true, // Offsets input safely away from home system bar pill
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 0.0,
                  bottom: 12.0,
                ), // Extra layout lift padding
                child: const SendMessageForm(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
