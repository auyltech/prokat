import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/constants/app_colors.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/features/chat/state/chat_provider.dart';
import 'package:prokat/features/chat/widgets/chat_tile.dart';
import 'package:shimmer/shimmer.dart';

class OwnerChatListScreen extends ConsumerStatefulWidget {
  const OwnerChatListScreen({super.key});

  @override
  ConsumerState<OwnerChatListScreen> createState() =>
      _OwnerChatListScreenState();
}

class _OwnerChatListScreenState extends ConsumerState<OwnerChatListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(chatProvider.notifier).getChatThreads();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chatState = ref.watch(chatProvider);
    final chats = chatState.conversations;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
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
        title: Text(
          "Chat",
          style: TextStyle(color: theme.colorScheme.onPrimary),
        ),
        backgroundColor: AppColors.teal700,
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.zero,
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
                  onTap: () =>
                      context.push('${AppRoutes.ownerChat}/${chat.id}'),
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
