import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/chat/providers/chat_providers.dart';
import 'package:prokat/features/chat/models/chat_message_model.dart';
import 'package:prokat/features/chat/service/chat_service.dart';
import 'package:prokat/features/chat/service/chat_socket_service.dart';
import 'package:prokat/features/chat/utils/chat_message_utils.dart';
import 'package:riverpod/riverpod.dart';

class ChatMessagesNotifier
    extends FamilyAsyncNotifier<QueryState<ChatMessageModel>, String> {
  late final ChatService api;
  late final String chatId;
  late final ChatSocketService socketService;

  @override
  Future<QueryState<ChatMessageModel>> build(String chatId) async {
    api = ref.read(chatServiceProvider);
    this.chatId = chatId;
    socketService = ref.read(chatSocketServiceProvider);

    return _fetchPage(1);
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

    try {
      socketService.sendMessage(
        chatId: chatId,
        message: trimmed,
        type: optimisticMessage.type,
        clientTempId: clientTempId,
      );

      return true;
    } catch (_) {
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
      items.add(normalized);
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
    final current = state.value;

    if (current == null) return;

    final items = current.items.map((message) {
      if (message.clientTempId == clientTempId) {
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
