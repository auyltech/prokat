import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/chat/providers/chat_providers.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/chat/widgets/chat_tile.dart';
import 'package:prokat/features/chat/widgets/chat_tile_skeleton.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:shimmer/shimmer.dart';

class ClientChatListScreen extends ConsumerStatefulWidget {
  const ClientChatListScreen({super.key});

  @override
  ConsumerState<ClientChatListScreen> createState() =>
      _ClientChatListScreenState();
}

class _ClientChatListScreenState extends ConsumerState<ClientChatListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreIfNeeded);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(clientChatsProvider.notifier).refreshIfStale();
    });
  }

  void _loadMoreIfNeeded() {
    if (!_scrollController.hasClients) return;

    if (_scrollController.position.extentAfter < 240) {
      ref.read(clientChatsProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_loadMoreIfNeeded)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final currentUserId = ref.watch(authProvider).currentUserId ?? "";
    final chatsAsync = ref.watch(clientChatsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(clientChatsProvider.notifier).refresh();
        },
        child: chatsAsync.when(
          loading: () => ListView.builder(
            controller: _scrollController,
            shrinkWrap: true,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            itemCount: 5,
            itemBuilder: (context, index) {
              return Shimmer.fromColors(
                baseColor: Colors.black12,
                highlightColor: Colors.grey.shade50,
                child: ChatTileSkeleton(index: index),
              );
            },
          ),

          error: (_, _) => ListView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(16),
            children: [
              EmptyStateTile(
                title: l10n.error,
                subtitle: l10n.couldNotLoadChats,
              ),
            ],
          ),

          data: (state) {
            final chats = state.items;

            if (chats.isEmpty) {
              return ListView(
                padding: EdgeInsets.all(12),
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  EmptyStateTile(
                    title: l10n.noChats,
                    subtitle: l10n.youHaveNoChats,
                    imageName: "empty_chats.png",
                  ),
                ],
              );
            }

            return ListView.separated(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: chats.length + (state.isLoadingMore ? 1 : 0),
              separatorBuilder: (_, _) => const Divider(
                height: 1,
                thickness: 1,
                indent: 16,
                endIndent: 16,
              ),
              itemBuilder: (context, index) {
                if (index == chats.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator.adaptive()),
                  );
                }

                final chat = chats[index];

                final url = chat.type == ChatType.direct
                    ? '${AppRoutes.clientChatList}/direct/${chat.id}'
                    : AppRoutes.clientChatSupport;

                return ChatTile(
                  chat: chat,
                  currentUserId: currentUserId,
                  onTap: () => context.push(url),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
