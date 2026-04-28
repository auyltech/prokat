import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
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
      await ref.read(chatProvider.notifier).loadConversations();
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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            elevation: 0,
            scrolledUnderElevation: 2,
            backgroundColor: theme.colorScheme.primary,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: theme.colorScheme.onPrimary,
              ),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.dashboard);
                }
              },
            ),
            title: Text(
              'Messages',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
              ),
            ),
            centerTitle: false,
          ),
          if (chatState.isLoadingConversations)
            _buildSliverSkeleton()
          else if (chatState.error != null && chats.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text(chatState.error!)),
            )
          else if (chats.isEmpty)
            _buildSliverEmptyState(theme)
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final chat = chats[index];
                  return ChatTile(
                    chat: chat,
                    currentUserId: chatState.currentUserId,
                    onTap: () => context.push('${AppRoutes.chat}/${chat.id}'),
                  );
                }, childCount: chats.length),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildSliverSkeleton() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Shimmer.fromColors(
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
          childCount: 5,
        ),
      ),
    );
  }

  Widget _buildSliverEmptyState(ThemeData theme) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: theme.disabledColor),
          const SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.disabledColor,
            ),
          ),
        ],
      ),
    );
  }
}
