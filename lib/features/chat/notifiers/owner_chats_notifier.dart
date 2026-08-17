import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/chat/providers/chat_dependencies.dart';
import 'package:prokat/features/chat/models/chat_message_model.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/chat/service/chat_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/auth/providers/authenticated_session_scope.dart';

class OwnerChatsNotifier extends AsyncNotifier<QueryState<ChatModel>> {
  ChatService get api => ref.read(chatServiceProvider);
  Future<void>? _refreshing;
  AuthenticatedSessionScopeKey? _refreshingScope;
  AuthenticatedSessionScopeKey? _stateScope;

  @override
  Future<QueryState<ChatModel>> build() async {
    final scope = ref.watch(authenticatedSessionScopeKeyProvider);
    if (scope == null) {
      _stateScope = null;
      return const QueryState(itemsPerPage: 20, count: 0);
    }

    final next = await _fetchPage(1, scope);
    if (!isAuthenticatedSessionScopeCurrent(ref, scope)) {
      return const QueryState(itemsPerPage: 20, count: 0);
    }
    _stateScope = scope;
    return next;
  }

  Future<QueryState<ChatModel>> _fetchPage(
    int page,
    AuthenticatedSessionScopeKey scope,
  ) async {
    if (!isAuthenticatedSessionScopeCurrent(ref, scope)) {
      return const QueryState(itemsPerPage: 20, count: 0);
    }

    final response = await api.getOwnerChats(page: page, itemsPerPage: 20);
    if (!isAuthenticatedSessionScopeCurrent(ref, scope)) {
      return const QueryState(itemsPerPage: 20, count: 0);
    }

    final result = response.data;

    if (!response.success || result == null) {
      throw Exception(response.message);
    }

    return QueryState(
      items: _sortChats(result.items),
      page: result.page,
      itemsPerPage: result.itemsPerPage,
      count: result.count,
      lastFetchedAt: DateTime.now(),
    );
  }

  Future<void> refresh() {
    final scope = readAuthenticatedSessionScope(ref);
    if (scope == null) return Future<void>.value();

    final active = _refreshing;
    if (active != null && _refreshingScope == scope) return active;

    final operation = _refresh(scope);
    _refreshing = operation;
    _refreshingScope = scope;
    return operation.whenComplete(() {
      if (identical(_refreshing, operation)) {
        _refreshing = null;
        _refreshingScope = null;
      }
    });
  }

  Future<void> _refresh(AuthenticatedSessionScopeKey scope) async {
    if (!isAuthenticatedSessionScopeCurrent(ref, scope)) return;

    if (state.isLoading) {
      try {
        await future;
        return;
      } catch (_) {}
      if (!isAuthenticatedSessionScopeCurrent(ref, scope)) return;
    }

    final previous = _stateScope == scope ? state.value : null;
    if (previous == null) {
      state = const AsyncLoading();
      final next = await AsyncValue.guard(() => _fetchPage(1, scope));
      if (isAuthenticatedSessionScopeCurrent(ref, scope)) {
        _stateScope = scope;
        state = next;
      }
      return;
    }

    state = AsyncData(previous.copyWith(isRefreshing: true));
    // state = AsyncLoading<QueryState<ChatModel>>().copyWithPrevious(state);

    try {
      final next = await _fetchPage(1, scope);
      if (isAuthenticatedSessionScopeCurrent(ref, scope)) {
        _stateScope = scope;
        state = AsyncData(next);
      }
    } catch (error) {
      if (isAuthenticatedSessionScopeCurrent(ref, scope)) {
        state = AsyncData(previous.withRefreshError(error));
      }
    }
  }

  Future<void> loadMore() async {
    final scope = readAuthenticatedSessionScope(ref);
    if (scope == null || _stateScope != scope) return;

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

      if (!isAuthenticatedSessionScopeCurrent(ref, scope)) return;

      if (!response.success || result == null) {
        state = AsyncData(current.copyWith(isLoadingMore: false));
        return;
      }

      state = AsyncData(
        current.copyWith(
          items: _mergeChats(current.items, result.items),
          page: result.page,
          itemsPerPage: result.itemsPerPage,
          count: result.count,
          isLoadingMore: false,
          lastFetchedAt: DateTime.now,
        ),
      );
    } catch (_) {
      if (isAuthenticatedSessionScopeCurrent(ref, scope)) {
        state = AsyncData(current.copyWith(isLoadingMore: false));
      }
    }
  }

  Future<void> invalidate() async {
    final current = state.value;
    if (current == null) return;

    state = AsyncData(current.copyWith(lastFetchedAt: () => null));
  }

  Future<void> refreshIfStale() async {
    final scope = readAuthenticatedSessionScope(ref);
    if (scope == null) return;

    if (state.isLoading) {
      try {
        await future;
      } catch (_) {}
    }
    if (!isAuthenticatedSessionScopeCurrent(ref, scope)) return;
    final current = state.value;

    if (_stateScope != scope || current == null || current.isStale) {
      await refresh();
    }
  }

  void upsert(ChatModel chat) {
    if (!_canMutateCurrentScope) return;
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
    if (!_canMutateCurrentScope) return;
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
    if (!_canMutateCurrentScope) return;
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

  bool get _canMutateCurrentScope {
    final scope = readAuthenticatedSessionScope(ref);
    return scope != null && _stateScope == scope;
  }

  List<ChatModel>? cachedItemsForScope(AuthenticatedSessionScopeKey scope) {
    if (_stateScope != scope) return null;
    return state.asData?.value.items;
  }

  List<ChatModel> _mergeChats(
    List<ChatModel> existing,
    List<ChatModel> incoming,
  ) {
    final chats = <String, ChatModel>{
      for (final chat in existing) chat.id: chat,
      for (final chat in incoming) chat.id: chat,
    };

    return _sortChats(chats.values.toList());
  }

  List<ChatModel> _sortChats(List<ChatModel> chats) {
    final sorted = List<ChatModel>.from(chats);
    sorted.sort((a, b) {
      final aDate = a.lastMessage?.createdAt ?? a.updatedAt ?? DateTime(0);
      final bDate = b.lastMessage?.createdAt ?? b.updatedAt ?? DateTime(0);
      return bDate.compareTo(aDate);
    });
    return sorted;
  }
}
