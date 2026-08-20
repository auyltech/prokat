import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/auth/providers/authenticated_session_scope.dart';
import 'package:prokat/features/chat/providers/chat_providers.dart';
import 'package:prokat/features/chat/models/chat_message_model.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/chat/service/chat_service.dart';
import 'package:prokat/features/workflow/models/workflow_update.dart';
import 'package:prokat/features/workflow/utils/workflow_cache_patch.dart';

class CurrentChatNotifier extends FamilyAsyncNotifier<ChatModel?, String> {
  ChatService get api => ref.read(chatServiceProvider);

  late String _chatId;
  DateTime? _lastFetchedAt;
  Future<void>? _refreshing;
  AuthenticatedSessionScopeKey? _refreshingScope;
  AuthenticatedSessionScopeKey? _stateScope;

  @override
  Future<ChatModel?> build(String chatId) async {
    _chatId = chatId;

    final scope = ref.watch(authenticatedSessionScopeKeyProvider);
    if (scope == null) {
      _lastFetchedAt = null;
      _stateScope = null;
      return null;
    }

    final next = await _fetch(scope);
    if (!isAuthenticatedSessionScopeCurrent(ref, scope)) return null;
    _stateScope = scope;
    return next;
  }

  Future<ChatModel?> _fetch(AuthenticatedSessionScopeKey scope) async {
    final response = await api.getChatById(_chatId);

    if (!isAuthenticatedSessionScopeCurrent(ref, scope)) return null;

    if (!response.success || response.data == null) {
      throw Exception(response.message);
    }

    _lastFetchedAt = DateTime.now();
    return response.data;
  }

  void applyWorkflowDelta(WorkflowUpdate update) {
    if (!_canMutateCurrentScope) return;
    final chat = state.value;
    if (chat == null) return;
    state = AsyncData(applyWorkflowDeltaToChat(chat, update));
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

    final hadData = _stateScope == scope && state is AsyncData<ChatModel?>;
    final previous = hadData ? state.valueOrNull : null;
    if (!hadData) {
      state = const AsyncLoading();
      final next = await AsyncValue.guard(() => _fetch(scope));
      if (isAuthenticatedSessionScopeCurrent(ref, scope)) {
        _stateScope = scope;
        state = next;
      }
      return;
    }

    try {
      final next = await _fetch(scope);
      if (isAuthenticatedSessionScopeCurrent(ref, scope)) {
        _stateScope = scope;
        final latest = state.value;
        state = AsyncData(
          next == null || latest == null
              ? next
              : mergeChatPreferringNewerWorkflow(next, latest),
        );
      }
    } catch (_) {
      if (isAuthenticatedSessionScopeCurrent(ref, scope)) {
        state = AsyncData(previous);
      }
    }
  }

  Future<void> refreshAll() async {
    if (readAuthenticatedSessionScope(ref) == null) return;
    final refreshes = <Future<void>>[refresh()];
    final messages = chatMessagesProvider(_chatId);
    if (ref.exists(messages)) {
      refreshes.add(ref.read(messages.notifier).refresh());
    }
    await Future.wait(refreshes);
  }

  Future<void> refreshIfStale({
    Duration staleAfter = const Duration(minutes: 5),
  }) async {
    final scope = readAuthenticatedSessionScope(ref);
    if (scope == null) return;

    if (state.isLoading) {
      try {
        await future;
      } catch (_) {}
    }
    if (!isAuthenticatedSessionScopeCurrent(ref, scope)) return;
    final fetchedAt = _lastFetchedAt;
    if (_stateScope != scope ||
        fetchedAt == null ||
        DateTime.now().difference(fetchedAt) >= staleAfter) {
      await refresh();
    }
  }

  void invalidate() => _lastFetchedAt = null;

  Future<void> markRead({required String messageId}) async {
    final scope = readAuthenticatedSessionScope(ref);
    if (scope == null || _stateScope != scope) return;

    final chat = state.value;

    if (chat == null) {
      return;
    }

    final response = await api.markChatRead(
      chatId: chat.id,
      messageId: messageId,
    );

    if (!isAuthenticatedSessionScopeCurrent(ref, scope) || !response.success) {
      return;
    }

    state = AsyncData(
      chat.copyWith(
        // newMessagesCount: 0,
      ),
    );
  }

  void setChat(ChatModel chat) {
    if (!_canMutateCurrentScope) return;
    state = AsyncData(chat);
  }

  void setLastMessage(ChatMessageModel message) {
    if (!_canMutateCurrentScope) return;
    final chat = state.value;

    if (chat == null) {
      return;
    }

    state = AsyncData(
      chat.copyWith(lastMessage: message, updatedAt: message.createdAt),
    );
  }

  void closeChat() {
    if (!_canMutateCurrentScope) return;
    final chat = state.value;

    if (chat == null) {
      return;
    }

    state = AsyncData(chat.copyWith(status: ChatStatus.closed));
  }

  void archiveChat() {
    if (!_canMutateCurrentScope) return;
    final chat = state.value;

    if (chat == null) {
      return;
    }

    state = AsyncData(chat.copyWith(status: ChatStatus.archived));
  }

  bool get _canMutateCurrentScope {
    final scope = readAuthenticatedSessionScope(ref);
    return scope != null && _stateScope == scope;
  }
}
