import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/chat/providers/chat_providers.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/chat/widgets/chat_tile.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:shimmer/shimmer.dart';

class ClientChatListScreen extends ConsumerStatefulWidget {
  const ClientChatListScreen({super.key});

  @override
  ConsumerState<ClientChatListScreen> createState() =>
      _ClientChatListScreenState();
}

class _ClientChatListScreenState extends ConsumerState<ClientChatListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(clientChatsProvider.notifier).refreshIfStale();
    });
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
          loading: _buildSkeleton,

          error: (_, __) => ListView(
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
                children: [
                  EmptyStateTile(
                    title: l10n.noChats,
                    subtitle: l10n.youHaveNoChats,
                  ),
                ],
              );
            }

            return ListView.separated(
              itemCount: chats.length,
              separatorBuilder: (_, _) => const Divider(
                height: 1,
                thickness: 1,
                indent: 16,
                endIndent: 16,
              ),
              itemBuilder: (context, index) {
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
