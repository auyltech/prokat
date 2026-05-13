import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/features/chat/state/chat_provider.dart';
import 'package:prokat/features/chat/widgets/chat_tile.dart';
import 'package:shimmer/shimmer.dart';

class ClientChatListScreen extends ConsumerStatefulWidget {
  final String? bookingId;
  final String? requestId;

  const ClientChatListScreen({super.key, this.bookingId, this.requestId});

  @override
  ConsumerState<ClientChatListScreen> createState() =>
      _ClientChatListScreenState();
}

class _ClientChatListScreenState extends ConsumerState<ClientChatListScreen> {
  bool _handledLinkedNavigation = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(chatProvider.notifier).getChatThreads();
      await _openLinkedChatIfNeeded();
    });
  }

  Future<void> _openLinkedChatIfNeeded() async {
    if (_handledLinkedNavigation) {
      return;
    }

    final hasBookingId = (widget.bookingId ?? '').isNotEmpty;
    final hasRequestId = (widget.requestId ?? '').isNotEmpty;
    if (!hasBookingId && !hasRequestId) {
      return;
    }

    _handledLinkedNavigation = true;
    final chatId = await ref
        .read(chatProvider.notifier)
        .getChatId(bookingId: widget.bookingId, requestId: widget.requestId);

    if (!mounted) {
      return;
    }

    if ((chatId ?? '').isEmpty) {
      final error = ref.read(chatProvider).error ?? 'Unable to open chat';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    context.push('${AppRoutes.chat}/$chatId');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chatState = ref.watch(chatProvider);
    final chats = chatState.conversations;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        title: Text(
          'Chat',
          style: TextStyle(color: theme.colorScheme.onPrimary),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: theme.colorScheme.onPrimary,
          ),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.push(AppRoutes.ownerDashboard),
        ),
      ),
      body: ListView(
        children: [
          if (chatState.isLoadingConversations)
            _buildSkeleton()
          else if (chatState.error != null && chats.isEmpty)
            EmptyStateTile(title: "Error", subtitle: "Could not load chats")
          else if (chats.isEmpty)
            EmptyStateTile(
              title: "No Chats",
              subtitle: "You don't have any chats",
            )
          else
            ListView.builder(
              shrinkWrap:
                  true, // Tells the list to only take the space it needs
              physics:
                  const NeverScrollableScrollPhysics(), // Stops the inner list from trying to scroll separately
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                return ChatTile(
                  chat: chat,
                  currentUserId: chatState.currentUserId ?? "",
                  onTap: () => context.push('${AppRoutes.chat}/${chat.id}'),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        // Use ListView.builder if you need it to scroll
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          5,
          (index) => Shimmer.fromColors(
            baseColor: Colors.grey.shade200,
            highlightColor: Colors.grey.shade50,
            child: Container(
              height: 80,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
