import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/features/chat/state/chat_provider.dart';
import 'package:prokat/features/chat/widgets/chat_tile.dart';
import 'package:prokat/l10n/app_localizations.dart';
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
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (ref.read(chatProvider).conversations.isNotEmpty) {
        await ref.read(chatProvider.notifier).getChatThreads("client");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final chatState = ref.watch(chatProvider);
    final chats = chatState.conversations;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(chatProvider.notifier).getChatThreads("client");
        },
        child: ListView(
          children: [
            if (chatState.isLoadingConversations &&
                chatState.conversations.isEmpty)
              _buildSkeleton()
            else if (chatState.error != null && chats.isEmpty)
              EmptyStateTile(
                title: l10n.error,
                subtitle: l10n.couldNotLoadChats,
              )
            else if (chats.isEmpty)
              EmptyStateTile(title: l10n.noChats, subtitle: l10n.youHaveNoChats)
            else
              ListView.separated(
                separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  thickness: 1,
                  indent: 16,
                  endIndent: 16,
                ),
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
                        context.push('${AppRoutes.clientChatList}/${chat.id}'),
                  );
                },
              ),
          ],
        ),
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
