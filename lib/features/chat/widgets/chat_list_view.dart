import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/core/widgets/primary_button.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/chat/models/chat_list_filter.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/chat/providers/chat_list_providers.dart';
import 'package:prokat/features/chat/widgets/chat_tile.dart';
import 'package:prokat/features/chat/widgets/chat_tile_skeleton.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:shimmer/shimmer.dart';

class ChatListView extends ConsumerStatefulWidget {
  const ChatListView({super.key, required this.isOwner});

  final bool isOwner;

  @override
  ConsumerState<ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends ConsumerState<ChatListView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final ScrollController _activeScrollController;
  late final ScrollController _archivedScrollController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _activeScrollController = ScrollController()
      ..addListener(() => _loadMoreIfNeeded(ChatListFilter.active));
    _archivedScrollController = ScrollController()
      ..addListener(() => _loadMoreIfNeeded(ChatListFilter.archived));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshIfStale(ChatListFilter.active);
    });

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      _refreshIfStale(
        _tabController.index == 0
            ? ChatListFilter.active
            : ChatListFilter.archived,
      );
    });
  }

  void _loadMoreIfNeeded(ChatListFilter filter) {
    final controller = filter == ChatListFilter.active
        ? _activeScrollController
        : _archivedScrollController;
    if (!controller.hasClients) return;
    if (controller.position.extentAfter >= 240) return;

    if (widget.isOwner) {
      ref.read(ownerChatsByFilterProvider(filter).notifier).loadMore();
    } else {
      ref.read(clientChatsByFilterProvider(filter).notifier).loadMore();
    }
  }

  void _refreshIfStale(ChatListFilter filter) {
    if (widget.isOwner) {
      ref.read(ownerChatsByFilterProvider(filter).notifier).refreshIfStale();
    } else {
      ref.read(clientChatsByFilterProvider(filter).notifier).refreshIfStale();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _activeScrollController.dispose();
    _archivedScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: l10n.chatsActiveTab),
              Tab(text: l10n.chatsArchiveTab),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ChatListPane(
                  isOwner: widget.isOwner,
                  filter: ChatListFilter.active,
                  scrollController: _activeScrollController,
                ),
                _ChatListPane(
                  isOwner: widget.isOwner,
                  filter: ChatListFilter.archived,
                  scrollController: _archivedScrollController,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatListPane extends ConsumerWidget {
  const _ChatListPane({
    required this.isOwner,
    required this.filter,
    required this.scrollController,
  });

  final bool isOwner;
  final ChatListFilter filter;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentUserId = ref.watch(authProvider).currentUserId ?? '';
    final chatsAsync = isOwner
        ? ref.watch(ownerChatsByFilterProvider(filter))
        : ref.watch(clientChatsByFilterProvider(filter));

    Future<void> refresh() {
      if (isOwner) {
        return ref.read(ownerChatsByFilterProvider(filter).notifier).refresh();
      }
      return ref.read(clientChatsByFilterProvider(filter).notifier).refresh();
    }

    return RefreshIndicator(
      onRefresh: refresh,
      child: chatsAsync.when(
        skipLoadingOnRefresh: !isOwner,
        loading: () => filter == ChatListFilter.active && !isOwner
            ? ListView.builder(
                controller: scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                itemCount: 5,
                itemBuilder: (context, index) {
                  return Shimmer.fromColors(
                    baseColor: Colors.black12,
                    highlightColor: Colors.grey.shade50,
                    child: ChatTileSkeleton(index: index),
                  );
                },
              )
            : _ownerSkeleton(scrollController),
        error: (_, _) => ListView(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            EmptyStateTile(
              title: l10n.error,
              subtitle: l10n.couldNotLoadChats,
              imageName: isOwner ? 'connection_error.png' : null,
            ),
          ],
        ),
        data: (state) {
          if (isOwner && state.isRefreshing) {
            return _ownerSkeleton(scrollController);
          }

          final chats = state.items;
          if (chats.isEmpty) {
            return ListView(
              controller: scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              children: [
                EmptyStateTile(
                  title: filter == ChatListFilter.archived
                      ? l10n.noArchivedChats
                      : l10n.noChats,
                  subtitle: filter == ChatListFilter.archived
                      ? l10n.youHaveNoArchivedChats
                      : l10n.youHaveNoChats,
                  imageName: 'empty_chats.png',
                  actionButton: PrimaryButton(
                    label: l10n.refresh,
                    isLoading: chatsAsync.isRefreshing,
                    icon: LucideIcons.refreshCw,
                    onPressed: refresh,
                  ),
                ),
              ],
            );
          }

          return ListView.separated(
            controller: scrollController,
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
              final url = isOwner
                  ? '${AppRoutes.ownerChatList}/direct/${chat.id}'
                  : chat.type == ChatType.direct
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
    );
  }
}

Widget _ownerSkeleton(ScrollController controller) {
  return ListView.builder(
    controller: controller,
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
    itemCount: 5,
    itemBuilder: (context, index) {
      return Shimmer(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade300,
            Colors.grey.shade100,
            Colors.grey.shade300,
          ],
          stops: const [0.3, 0.5, 0.7],
        ),
        child: Container(
          height: 80,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    },
  );
}
