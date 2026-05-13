import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/chat/state/chat_provider.dart';
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
      body: SafeArea(
        top: false, // AppBar handles the top safe area
        child: Column(
          children: [
            // 1. Top banner area (e.g. Booking requests)
            if (booking != null || request != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: BookingMessageBubble(booking: booking as BookingModel),
              ),

            // 2. Chat history area (Fills the remaining middle section)
            Expanded(
              child: chatState.isLoadingMessages
                  ? const Center(child: CircularProgressIndicator())
                  : chatState.error != null && messages.isEmpty
                  ? Center(child: Text(chatState.error!))
                  : ListView.builder(
                      reverse: true, // New messages appear at the bottom
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 12.0,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMe =
                            message.senderId == currentUserId ||
                            message.senderId == 'me';
                        return MessageBubble(message: message, isMe: isMe);
                      },
                    ),
            ),

            // 3. Static input area pinned to the bottom of the viewport
            const SendMessageForm(),
          ],
        ),
      ),
    );
  }
}
