import 'dart:async';

import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/chat/providers/chat_providers.dart';
import 'package:prokat/features/chat/models/chat_message_model.dart';
import 'package:prokat/features/chat/providers/current_chat_provider.dart';
import 'package:prokat/features/chat/service/chat_service.dart';
import 'package:prokat/features/chat/service/chat_socket_service.dart';
import 'package:prokat/features/chat/utils/chat_message_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatMessagesNotifier
    extends FamilyAsyncNotifier<QueryState<ChatMessageModel>, String> {
  late final ChatService api;
  late final String chatId;
  late final ChatSocketService socketService;

  void Function()? _removeMessageListener;
  final List<ChatMessageModel> _incomingBuffer = [];
  final Map<String, Timer> _pendingConfirmationTimers = {};
  bool _shouldMaintainSession = true;

  @override
  Future<QueryState<ChatMessageModel>> build(String chatId) async {
    api = ref.read(chatServiceProvider);
    this.chatId = chatId;
    socketService = ref.read(chatSocketServiceProvider);

    ref.onCancel(() {
      _shouldMaintainSession = false;
      unawaited(_deactivateChatSession().catchError((_) {}));
    });

    ref.onResume(() {
      _shouldMaintainSession = true;
      unawaited(_activateChatSession().catchError((_) {}));
    });

    ref.onDispose(() {
      _shouldMaintainSession = false;
      _removeMessageListener?.call();
      _removeMessageListener = null;
      for (final timer in _pendingConfirmationTimers.values) {
        timer.cancel();
      }
      _pendingConfirmationTimers.clear();
      unawaited(socketService.leaveChat(chatId).catchError((_) {}));
    });

    await _activateChatSession();

    final initial = await _fetchPage(1);
    final buffered = List<ChatMessageModel>.from(_incomingBuffer);
    _incomingBuffer.clear();

    Timer.run(_flushIncomingBuffer);

    if (buffered.isEmpty) {
      return initial;
    }

    return initial.copyWith(items: mergeMessages(initial.items, buffered));
  }

  Future<void> _activateChatSession() async {
    _shouldMaintainSession = true;

    _removeMessageListener ??= socketService.onNewMessage(
      _handleIncomingMessage,
    );

    await socketService.joinChat(chatId);
  }

  Future<void> _deactivateChatSession() async {
    _removeMessageListener?.call();
    _removeMessageListener = null;

    await socketService.leaveChat(chatId);
  }

  void _handleIncomingMessage(ChatMessageModel message) {
    if (message.chatId != chatId || !_shouldMaintainSession) {
      return;
    }

    final current = state.value;
    if (current == null) {
      _incomingBuffer.add(message);
      return;
    }

    final clientTempId = message.clientTempId?.trim();
    if (clientTempId != null && clientTempId.isNotEmpty) {
      _pendingConfirmationTimers.remove(clientTempId)?.cancel();
    }

    final replaced = replacePending(message);
    if (!replaced) {
      mergeIncoming(message);
    }

    _updateRelatedChatState(message);
  }

  void _flushIncomingBuffer() {
    if (!_shouldMaintainSession ||
        state.value == null ||
        _incomingBuffer.isEmpty) {
      return;
    }

    final buffered = List<ChatMessageModel>.from(_incomingBuffer);
    _incomingBuffer.clear();

    for (final message in buffered) {
      _handleIncomingMessage(message);
    }
  }

  void _updateRelatedChatState(ChatMessageModel message) {
    if (ref.exists(currentChatProvider(chatId))) {
      ref.read(currentChatProvider(chatId).notifier).setLastMessage(message);
    }

    if (ref.exists(clientChatsProvider)) {
      ref
          .read(clientChatsProvider.notifier)
          .updatePreview(chatId: chatId, message: message);
    }

    if (ref.exists(ownerChatsProvider)) {
      ref
          .read(ownerChatsProvider.notifier)
          .updatePreview(chatId: chatId, message: message);
    }
  }

  Future<QueryState<ChatMessageModel>> _fetchPage(int page) async {
    final response = await api.getMessages(
      chatId: chatId,
      page: page,
      itemsPerPage: 50,
    );

    if (!response.success || response.data == null) {
      throw Exception(response.message);
    }

    final result = response.data;

    return QueryState(
      items: result?.items ?? const [],
      page: result?.page ?? 1,
      itemsPerPage: result?.itemsPerPage ?? 50,
      count: result?.count ?? 0,
      lastFetchedAt: DateTime.now(),
    );
  }

  Future<bool> sendMessage(String text) async {
    final trimmed = text.trim();

    if (trimmed.isEmpty) {
      return false;
    }

    final auth = ref.read(authProvider);
    final user = auth.session?.user;

    if (user == null || user.id == null || user.id!.isEmpty) {
      return false;
    }

    final clientTempId = DateTime.now().microsecondsSinceEpoch.toString();

    final optimisticMessage = ChatMessageModel(
      id: clientTempId,
      chatId: chatId,
      senderId: user.id!,
      senderName: user.displayName,
      senderAvatarUrl: user.imageUrl,
      content: trimmed,
      type: 'TEXT',
      clientTempId: clientTempId,
      isPending: true,
      isFailed: false,
      createdAt: DateTime.now(),
    );

    insertPending(optimisticMessage);
    _updateRelatedChatState(optimisticMessage);

    try {
      await _activateChatSession();

      await socketService.sendMessage(
        chatId: chatId,
        message: trimmed,
        type: optimisticMessage.type,
        clientTempId: clientTempId,
      );

      _pendingConfirmationTimers[clientTempId]?.cancel();
      _pendingConfirmationTimers[clientTempId] = Timer(
        const Duration(seconds: 10),
        () => markFailed(clientTempId),
      );

      return true;
    } catch (error) {
      markFailed(clientTempId);
      return false;
    }
  }

  Future<bool> retry(ChatMessageModel message) async {
    remove(message.id);

    return sendMessage(message.content);
  }

  Future<void> refresh() async {
    final previous = state.value;

    if (previous == null) {
      state = const AsyncLoading();
    } else {
      state = AsyncData(previous.copyWith(isRefreshing: true));
    }

    state = await AsyncValue.guard(() async {
      await _activateChatSession();
      final fresh = await _fetchPage(1);

      return previous == null
          ? fresh
          : previous.copyWith(
              items: mergeMessages(previous.items, fresh.items),
              page: fresh.page,
              itemsPerPage: fresh.itemsPerPage,
              count: fresh.count,
              lastFetchedAt: DateTime.now(),
              isRefreshing: false,
            );
    });
  }

  Future<void> loadMore() async {
    final current = state.value;

    if (current == null) return;

    if (!current.hasMore) return;

    if (current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final response = await api.getMessages(
        chatId: chatId,
        page: current.page + 1,
        itemsPerPage: current.itemsPerPage,
      );

      if (!response.success || response.data == null) {
        state = AsyncData(current.copyWith(isLoadingMore: false));
        return;
      }

      final result = response.data!;

      state = AsyncData(
        current.copyWith(
          items: mergeMessages(current.items, result.items),
          page: result.page,
          itemsPerPage: result.itemsPerPage,
          count: result.count,
          lastFetchedAt: DateTime.now(),
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  void mergeFetchedMessages(List<ChatMessageModel> messages) {
    final current = state.value;

    if (current == null) return;

    state = AsyncData(
      current.copyWith(items: mergeMessages(current.items, messages)),
    );
  }

  void mergeIncoming(ChatMessageModel message) {
    final current = state.value;

    if (current == null) return;

    state = AsyncData(
      current.copyWith(items: mergeIncomingMessages(current.items, message)),
    );
  }

  Future<void> invalidate() async {
    final current = state.value;

    if (current == null) return;

    state = AsyncData(current.copyWith(lastFetchedAt: null));
  }

  Future<void> refreshIfStale() async {
    final current = state.value;

    if (current == null) {
      await refresh();
      return;
    }

    if (current.isStale) {
      await refresh();
    }
  }

  void insertPending(ChatMessageModel message) {
    final current = state.value;

    if (current == null) return;

    final pending = message.copyWith(isPending: true, isFailed: false);

    state = AsyncData(
      current.copyWith(items: mergeIncomingMessages(current.items, pending)),
    );
  }

  bool replacePending(ChatMessageModel confirmed) {
    final current = state.value;

    if (current == null) {
      return false;
    }

    final normalized = confirmed.copyWith(isPending: false, isFailed: false);

    var replaced = false;

    final items = current.items.map((message) {
      if (message.clientTempId != null &&
          message.clientTempId == normalized.clientTempId) {
        replaced = true;
        return normalized;
      }

      return message;
    }).toList();

    if (!replaced) {
      return false;
    }

    state = AsyncData(current.copyWith(items: mergeMessages(const [], items)));

    return replaced;
  }

  void remove(String messageId) {
    final current = state.value;

    if (current == null) return;

    state = AsyncData(
      current.copyWith(
        items: current.items.where((e) => e.id != messageId).toList(),
      ),
    );
  }

  void markFailed(String clientTempId) {
    _pendingConfirmationTimers.remove(clientTempId)?.cancel();

    final current = state.value;

    if (current == null) return;

    final items = current.items.map((message) {
      if (message.clientTempId == clientTempId && message.isPending) {
        return message.copyWith(isPending: false, isFailed: true);
      }

      return message;
    }).toList();

    state = AsyncData(current.copyWith(items: items));
  }

  void clear() {
    final current = state.value;

    if (current == null) return;

    state = AsyncData(
      current.copyWith(
        items: const [],
        page: 1,
        count: 0,
        isLoadingMore: false,
        isRefreshing: false,
      ),
    );
  }

  // useful for reactions, edits, delete, read receipts, etc.
  ChatMessageModel? getMessage(String id) {
    final current = state.value;

    if (current == null) return null;

    for (final message in current.items) {
      if (message.id == id) {
        return message;
      }
    }

    return null;
  }
}
