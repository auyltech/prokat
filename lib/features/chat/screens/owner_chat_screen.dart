import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/chat/state/chat_provider.dart';
import 'package:prokat/features/chat/widgets/message_bubble.dart';

class OwnerChatScreen extends ConsumerStatefulWidget {
  final String chatId;

  const OwnerChatScreen({super.key, required this.chatId});

  @override
  ConsumerState<OwnerChatScreen> createState() => _OwnerChatScreenState();
}

class _OwnerChatScreenState extends ConsumerState<OwnerChatScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(chatProvider.notifier).openChatById(widget.chatId);
    });
  }

  @override
  void didUpdateWidget(covariant OwnerChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chatId != widget.chatId) {
      Future.microtask(() {
        ref.read(chatProvider.notifier).openChatById(widget.chatId);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    ref.read(chatProvider.notifier).leaveCurrentChat();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }

    ref.read(chatProvider.notifier).sendMessage(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final chatState = ref.watch(chatProvider);
    final authState = ref.watch(authProvider);
    final messages = chatState.messages;
    final currentChat = chatState.currentChat;

    final authUserId = authState.session?.user?.id;
    final currentUserId = (authUserId ?? '').isNotEmpty
        ? authUserId
        : chatState.currentUserId;

    final title = currentChat?.displayTitle(currentUserId ?? "") ?? 'Chat';
    final avatarUrl = currentChat?.displayImageUrl(
      currentUserId: currentUserId,
    );

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
          onTap: () =>
              context.push('${AppRoutes.ownerChat}/${widget.chatId}/info'),
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
                    Text(
                      'Tap for details',
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
        ),
      ),
      body: Column(
        children: [
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
            
          _buildInputSection(theme, chatState.isSendingMessage),
        ],
      ),
    );
  }

  Widget _buildInputSection(ThemeData theme, bool isSending) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Review offer and reply...',
                hintStyle: TextStyle(color: theme.disabledColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                fillColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _sendMessage,
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  if (isSending)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
