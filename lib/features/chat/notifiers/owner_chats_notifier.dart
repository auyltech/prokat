import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/chat/providers/chat_providers.dart';
import 'package:prokat/features/chat/models/chat_message_model.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/chat/service/chat_service.dart';
import 'package:riverpod/riverpod.dart';

class OwnerChatsNotifier extends AsyncNotifier<QueryState<ChatModel>> {
  late final ChatService api;

  @override
  Future<QueryState<ChatModel>> build() async {
    api = ref.read(chatServiceProvider);

    return _fetchPage(1);
  }

  Future<QueryState<ChatModel>> _fetchPage(int page) async {
    final response = await api.getOwnerChats(page: page, itemsPerPage: 20);

    final result = response.data;

    return QueryState(
      items: result?.items ?? const [],
      page: result?.page ?? 1,
      itemsPerPage: result?.itemsPerPage ?? 20,
      count: result?.count ?? 0,
      lastFetchedAt: DateTime.now(),
    );
  }

  Future<void> refresh() async {
    final previous = state.value;

    if (previous == null) {
      state = const AsyncLoading();
    } else {
      state = AsyncData(previous.copyWith(isRefreshing: true));
    }

    state = await AsyncValue.guard(() async {
      return _fetchPage(1);
    });
  }

  Future<void> loadMore() async {
    final current = state.value;

    if (current == null || !current.hasMore || current.isLoadingMore) {
      return;
    }

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final response = await api.getOwnerChats(
        page: current.page + 1,
        itemsPerPage: current.itemsPerPage,
      );

      final result = response.data;

      if (!response.success || result == null) {
        state = AsyncData(current.copyWith(isLoadingMore: false));
        return;
      }

      state = AsyncData(
        current.copyWith(
          items: [...current.items, ...result.items],
          page: result.page,
          itemsPerPage: result.itemsPerPage,
          count: result.count,
          isLoadingMore: false,
          lastFetchedAt: DateTime.now(),
        ),
      );
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  Future<void> invalidate() async {
    final current = state.value;
    if (current == null) return;

    state = AsyncData(current.copyWith(lastFetchedAt: null));
  }

  Future<void> refreshIfStale() async {
    final current = state.value;

    if (current == null || current.isStale) {
      await refresh();
    }
  }

  void upsert(ChatModel chat) {
    final current = state.value;
    if (current == null) return;

    final items = [...current.items];

    final index = items.indexWhere((e) => e.id == chat.id);

    if (index >= 0) {
      items[index] = chat;
    } else {
      items.insert(0, chat);
    }

    items.sort((a, b) {
      final aDate = a.lastMessage?.createdAt ?? a.updatedAt ?? DateTime(0);
      final bDate = b.lastMessage?.createdAt ?? b.updatedAt ?? DateTime(0);

      return bDate.compareTo(aDate);
    });

    state = AsyncData(current.copyWith(items: items));
  }

  void remove(String chatId) {
    final current = state.value;
    if (current == null) return;

    state = AsyncData(
      current.copyWith(
        items: current.items.where((e) => e.id != chatId).toList(),
      ),
    );
  }

  void updatePreview({
    required String chatId,
    required ChatMessageModel message,
  }) {
    final current = state.value;
    if (current == null) return;

    final items = current.items.map((chat) {
      if (chat.id != chatId) {
        return chat;
      }

      return chat.copyWith(lastMessage: message, updatedAt: message.createdAt);
    }).toList();

    items.sort((a, b) {
      final aDate = a.lastMessage?.createdAt ?? a.updatedAt ?? DateTime(0);
      final bDate = b.lastMessage?.createdAt ?? b.updatedAt ?? DateTime(0);

      return bDate.compareTo(aDate);
    });

    state = AsyncData(current.copyWith(items: items));
  }

  void markChatRead(String chatId) {
    // We'll implement this after updating ChatModel.copyWith
    // to support newMessagesCount.
  }
}
