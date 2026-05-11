import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/chat/state/chat_provider.dart';
import 'package:prokat/features/chat/state/chat_message_model.dart';
import 'package:prokat/features/chat/widgets/message_bubble.dart';
import 'package:prokat/features/chat/widgets/booking_message_bubble.dart';
import 'package:prokat/features/chat/widgets/request_message_bubble.dart';
import 'package:prokat/features/chat/widgets/send_message_form.dart';
import 'package:prokat/features/requests/models/request_model.dart';

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
          if (booking != null || request != null)
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _ChatContextHeader(
                  chatId: currentChat?.id ?? widget.chatId,
                  booking: booking,
                  request: request,
                ),
              ),
            ),

          if (chatState.isLoadingMessages)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (chatState.error != null && messages.isEmpty)
            Expanded(child: Center(child: Text(chatState.error!)))
          else
            Expanded(
              child: Container(
                color: theme.colorScheme.surface,
                child: ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 24,
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
            ),

          SendMessageForm(),
        ],
      ),
    );
  }
}

class _ChatContextHeader extends StatelessWidget {
  final String chatId;
  final BookingModel? booking;
  final RequestModel? request;

  const _ChatContextHeader({
    required this.chatId,
    required this.booking,
    required this.request,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<Widget> bubbles = [];

    if (booking != null) {
      bubbles.add(
        BookingMessageBubble(
          booking: booking as BookingModel,
          // message: ChatMessageModel(
          //   id: 'booking_header',
          //   chatId: chatId,
          //   senderId: '',
          //   type: 'BOOKING',
          //   content: _bookingSummary(booking as BookingModel),
          //   createdAt: DateTime.now(),
          // ),
        ),
      );
    }

    if (request != null) {
      bubbles.add(
        RequestMessageBubble(
          message: ChatMessageModel(
            id: 'request_header',
            chatId: chatId,
            senderId: '',
            type: 'REQUEST',
            content: _requestSummary(request as RequestModel),
            createdAt: DateTime.now(),
          ),
        ),
      );
    }

    if (bubbles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...bubbles,
          Divider(color: theme.dividerColor.withValues(alpha: 0.35)),
        ],
      ),
    );
  }

  static String _requestSummary(RequestModel request) {
    try {
      final categoryName = request.category?.name.toString();
      final capacity = request.capacity.toString();
      final offeredRate = request.offeredRate.toString();
      final status = request.status.toString();

      final parts = <String>[
        'Request',
        if ((categoryName ?? '').isNotEmpty) categoryName!,
        capacity,
        offeredRate,
        status,
      ];
      return parts.join(' • ');
    } catch (_) {
      return 'Request';
    }
  }
}
