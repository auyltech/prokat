import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/chat/providers/chat_providers.dart';
import 'package:prokat/features/chat/widgets/message_bubble.dart';

/// Inverted chat feed: newest messages sit at the bottom, older pages prepend
/// at the top when the user scrolls toward the oldest content.
class ChatMessageList extends ConsumerStatefulWidget {
  const ChatMessageList({
    super.key,
    required this.chatId,
    required this.currentUserId,
    required this.mode,
    this.currentChat,
  });

  final String chatId;
  final String currentUserId;
  final AppMode mode;
  final ChatModel? currentChat;

  @override
  ConsumerState<ChatMessageList> createState() => _ChatMessageListState();
}

class _ChatMessageListState extends ConsumerState<ChatMessageList>
    with WidgetsBindingObserver {
  static const _loadMoreExtent = 240.0;
  static const _stickToNewestExtent = 48.0;

  final ScrollController _controller = ScrollController();
  String? _newestMessageId;
  bool _didInitialLoadMoreCheck = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller.addListener(_loadMoreIfNeeded);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _dismissDisplayedChatPush();
    });
  }

  @override
  void didUpdateWidget(covariant ChatMessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chatId != widget.chatId) {
      _newestMessageId = null;
      _didInitialLoadMoreCheck = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _dismissDisplayedChatPush();
      });
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    _keepNewestAboveComposer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller
      ..removeListener(_loadMoreIfNeeded)
      ..dispose();
    super.dispose();
  }

  void _dismissDisplayedChatPush() {
    ref
        .read(chatMessagesProvider(widget.chatId).notifier)
        .dismissDisplayedPush();
  }

  void _loadMoreIfNeeded() {
    if (!_controller.hasClients) return;

    final messages = ref.read(chatMessagesProvider(widget.chatId)).valueOrNull;
    if (messages == null ||
        messages.isLoadingMore ||
        messages.isRefreshing ||
        !messages.hasMore) {
      return;
    }

    if (_controller.position.extentAfter > _loadMoreExtent) return;

    unawaited(
      ref.read(chatMessagesProvider(widget.chatId).notifier).loadMore(),
    );
  }

  void _scheduleLoadMoreCheck() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadMoreIfNeeded();
    });
  }

  void _keepNewestAboveComposer() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) return;

      final position = _controller.position;
      if (!position.hasContentDimensions) return;
      if (position.pixels > _stickToNewestExtent) return;

      _controller.jumpTo(0);
    });
  }

  void _scrollToNewest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) return;

      final position = _controller.position;
      if (!position.hasContentDimensions) return;
      if (position.pixels <= 0.5) return;

      unawaited(
        _controller.animateTo(
          0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chatId));

    ref.listen(chatMessagesProvider(widget.chatId), (previous, next) {
      final previousNewest = previous?.valueOrNull?.items.firstOrNull?.id;
      final nextNewest = next.valueOrNull?.items.firstOrNull?.id;
      final newestChanged = nextNewest != null && nextNewest != previousNewest;

      if (newestChanged) {
        _newestMessageId = nextNewest;
        _scrollToNewest();
      }

      final loadedMore =
          previous?.valueOrNull?.isLoadingMore == true &&
          next.valueOrNull?.isLoadingMore == false;
      if (loadedMore || newestChanged) {
        _scheduleLoadMoreCheck();
      }
    });

    return messagesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator.adaptive()),
      error: (_, _) => const Center(child: EmptyStateTile()),
      data: (messagesData) {
        if (messagesData.items.isEmpty) {
          final flow = ProkatFlowScope.maybeOf(context);
          if (flow != null &&
              widget.currentChat?.inquiryEquipmentId != null &&
              widget.currentChat?.bookingId == null) {
            final l10n = AppLocalizations.of(context)!;
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 36,
                      color: flow.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.inquiryStatus,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        color: flow.title,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.mode == AppMode.clientMode
                          ? l10n.inquiryClientEmptyHint
                          : l10n.inquiryOwnerEmptyHint,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        color: flow.secondary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return const Center(child: EmptyStateTile());
        }

        final newestId = messagesData.items.first.id;
        _newestMessageId ??= newestId;

        if (!_didInitialLoadMoreCheck) {
          _didInitialLoadMoreCheck = true;
          _scheduleLoadMoreCheck();
        }

        final extraLoadingItem = messagesData.isLoadingMore ? 1 : 0;

        return ListView.separated(
          controller: _controller,
          reverse: true,
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          itemCount: messagesData.items.length + extraLoadingItem,
          separatorBuilder: (_, _) => const SizedBox(height: 4),
          itemBuilder: (context, index) {
            if (index >= messagesData.items.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
              );
            }

            final message = messagesData.items[index];
            return MessageBubble(
              key: ValueKey(message.clientTempId ?? message.id),
              message: message,
              isMe:
                  message.senderId == widget.currentUserId ||
                  message.senderId == 'me',
              mode: widget.mode,
              currentChat: widget.currentChat,
            );
          },
        );
      },
    );
  }
}
