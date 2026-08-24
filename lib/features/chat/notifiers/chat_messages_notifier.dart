import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/auth/providers/authenticated_session_scope.dart';
import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/chat/providers/chat_dependencies.dart';
import 'package:prokat/features/chat/providers/chat_list_providers.dart';
import 'package:prokat/features/chat/models/chat_message_model.dart';
import 'package:prokat/features/chat/providers/current_chat_provider.dart';
import 'package:prokat/features/chat/service/chat_service.dart';
import 'package:prokat/features/chat/service/chat_socket_service.dart';
import 'package:prokat/features/chat/utils/chat_message_utils.dart';
import 'package:prokat/core/config/env.dart';
import 'package:prokat/features/chat/utils/chat_resume_sync_observer.dart';
import 'package:prokat/features/notifications/providers/push_notification_service_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatMessagesNotifier
    extends FamilyAsyncNotifier<QueryState<ChatMessageModel>, String> {
  ChatService get api => ref.read(chatServiceProvider);

  late String chatId;
  ChatSocketService? _socketService;

  void Function()? _removeMessageListener;
  final List<ChatMessageModel> _incomingBuffer = [];
  final Map<String, Timer> _pendingConfirmationTimers = {};
  bool _shouldMaintainSession = true;
  Future<void>? _refreshing;
  AuthenticatedSessionScopeKey? _refreshingScope;
  AuthenticatedSessionScopeKey? _socketScope;
  AuthenticatedSessionScopeKey? _stateScope;
  bool _isDisposed = false;
  ChatResumeSyncObserver? _lifecycleObserver;

  @override
  Future<QueryState<ChatMessageModel>> build(String chatId) async {
    _isDisposed = false;
    this.chatId = chatId;

    final scope = ref.watch(authenticatedSessionScopeKeyProvider);
    if (scope == null) {
      _shouldMaintainSession = false;
      _stateScope = null;
      return const QueryState(itemsPerPage: 50, count: 0);
    }

    final socketService = ref.read(chatSocketServiceProvider);
    _socketService = socketService;

    ref.onCancel(() {
      if (_socketScope != scope) return;
      _shouldMaintainSession = false;
      unawaited(
        _deactivateChatSession(scope, socketService, chatId).catchError((_) {}),
      );
    });

    ref.onResume(() {
      if (!isAuthenticatedSessionScopeCurrent(ref, scope)) return;
      unawaited(
        _activateChatSession(
          scope,
          socketService,
          chatId,
        ).then<void>((_) {}).catchError((_) {}),
      );
    });

    _ensureLifecycleObserver();

    ref.onDispose(() {
      _isDisposed = true;
      _removeLifecycleObserver();
      if (_socketScope == scope) {
        _shouldMaintainSession = false;
        _removeMessageListener?.call();
        _removeMessageListener = null;
        _socketScope = null;
        _socketService = null;
        _incomingBuffer.clear();
        for (final timer in _pendingConfirmationTimers.values) {
          timer.cancel();
        }
        _pendingConfirmationTimers.clear();
      }
      unawaited(socketService.leaveChat(chatId).catchError((_) {}));
    });

    final activated = await _activateChatSession(scope, socketService, chatId);
    if (!activated) {
      return const QueryState(itemsPerPage: 50, count: 0);
    }

    final initial = await _fetchPage(1, scope);
    if (!isAuthenticatedSessionScopeCurrent(ref, scope)) {
      return const QueryState(itemsPerPage: 50, count: 0);
    }
    final buffered = List<ChatMessageModel>.from(_incomingBuffer);
    _incomingBuffer.clear();
    _stateScope = scope;

    Timer.run(() {
      if (_isDisposed) return;
      _flushIncomingBuffer(scope);
    });

    if (buffered.isEmpty) {
      return initial;
    }

    final items = mergeMessages(initial.items, buffered);
    final added = items.length - initial.items.length;
    return initial.copyWith(
      items: items,
      count: initial.count + (added > 0 ? added : 0),
    );
  }

  void _ensureLifecycleObserver() {
    if (_lifecycleObserver != null) return;

    late final WidgetsBinding binding;
    try {
      binding = WidgetsBinding.instance;
    } catch (_) {
      return;
    }

    final observer = ChatResumeSyncObserver(
      onResumeFromBackground: _onAppResumeFromBackground,
    );
    _lifecycleObserver = observer;
    binding.addObserver(observer);
  }

  void _removeLifecycleObserver() {
    final observer = _lifecycleObserver;
    if (observer == null) return;
    _lifecycleObserver = null;
    try {
      WidgetsBinding.instance.removeObserver(observer);
    } catch (_) {}
  }

  void _onAppResumeFromBackground() {
    if (_isDisposed || !_shouldMaintainSession) return;

    unawaited(refresh());
    _dismissDisplayedChatPush();

    final currentChat = currentChatProvider(chatId);
    if (ref.exists(currentChat)) {
      unawaited(ref.read(currentChat.notifier).refresh());
    }
  }

  void dismissDisplayedPush() => _dismissDisplayedChatPush();

  void _dismissDisplayedChatPush() {
    if (!Env.pushNotificationsEnabled) return;

    try {
      unawaited(
        ref
            .read(pushNotificationServiceProvider)
            .dismissDisplayedForChat(chatId),
      );
    } catch (_) {}
  }

  Future<bool> _activateChatSession(
    AuthenticatedSessionScopeKey scope, [
    ChatSocketService? requestedSocket,
    String? requestedChatId,
  ]) async {
    if (!isAuthenticatedSessionScopeCurrent(ref, scope)) return false;

    final socket =
        requestedSocket ??
        _socketService ??
        ref.read(chatSocketServiceProvider);
    if (socket == null) return false;
    final activeChatId = requestedChatId ?? chatId;

    if (_socketScope != scope) {
      _removeMessageListener?.call();
      _removeMessageListener = null;
      _incomingBuffer.clear();
      for (final timer in _pendingConfirmationTimers.values) {
        timer.cancel();
      }
      _pendingConfirmationTimers.clear();
    }

    _socketService = socket;
    _socketScope = scope;
    _shouldMaintainSession = true;

    _removeMessageListener ??= socket.onNewMessage(
      (message) => _handleIncomingMessage(message, scope),
    );

    await socket.joinChat(activeChatId);

    if (!isAuthenticatedSessionScopeCurrent(ref, scope)) {
      if (_socketScope == scope) {
        _shouldMaintainSession = false;
        _removeMessageListener?.call();
        _removeMessageListener = null;
        _socketScope = null;
      }
      if (readAuthenticatedSessionScope(ref) == null) {
        await socket.leaveChat(activeChatId);
      }
      return false;
    }

    return true;
  }

  Future<void> _deactivateChatSession(
    AuthenticatedSessionScopeKey scope,
    ChatSocketService socket,
    String activeChatId,
  ) async {
    if (_socketScope != scope) return;

    _removeMessageListener?.call();
    _removeMessageListener = null;

    final currentScope = readAuthenticatedSessionScope(ref);
    if (currentScope == null || currentScope == scope) {
      await socket.leaveChat(activeChatId);
    }
  }

  void _handleIncomingMessage(
    ChatMessageModel message,
    AuthenticatedSessionScopeKey scope,
  ) {
    if (!isAuthenticatedSessionScopeCurrent(ref, scope) ||
        _socketScope != scope ||
        message.chatId != chatId ||
        !_shouldMaintainSession) {
      return;
    }

    final current = state.value;
    if (_stateScope != scope || current == null) {
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

    _updateRelatedChatState(message, scope);
  }

  void _flushIncomingBuffer(AuthenticatedSessionScopeKey scope) {
    if (!isAuthenticatedSessionScopeCurrent(ref, scope) ||
        _socketScope != scope ||
        !_shouldMaintainSession ||
        state.value == null ||
        _incomingBuffer.isEmpty) {
      return;
    }

    final buffered = List<ChatMessageModel>.from(_incomingBuffer);
    _incomingBuffer.clear();

    for (final message in buffered) {
      _handleIncomingMessage(message, scope);
    }
  }

  void _updateRelatedChatState(
    ChatMessageModel message,
    AuthenticatedSessionScopeKey scope,
  ) {
    if (!isAuthenticatedSessionScopeCurrent(ref, scope)) return;

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

  Future<QueryState<ChatMessageModel>> _fetchPage(
    int page,
    AuthenticatedSessionScopeKey scope,
  ) async {
    if (!isAuthenticatedSessionScopeCurrent(ref, scope)) {
      return const QueryState(itemsPerPage: 50, count: 0);
    }

    final response = await api.getMessages(
      chatId: chatId,
      page: page,
      itemsPerPage: 50,
    );

    if (!isAuthenticatedSessionScopeCurrent(ref, scope)) {
      return const QueryState(itemsPerPage: 50, count: 0);
    }

    if (!response.success || response.data == null) {
      throw Exception(response.message);
    }

    final result = response.data;

    return QueryState(
      items: sortMessages(result?.items ?? const []),
      page: result?.page ?? 1,
      itemsPerPage: result?.itemsPerPage ?? 50,
      count: result?.count ?? 0,
      lastFetchedAt: DateTime.now(),
    );
  }

  Future<bool> sendMessage(String text) async {
    final scope = readAuthenticatedSessionScope(ref);
    if (scope == null) return false;

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
    _updateRelatedChatState(optimisticMessage, scope);

    try {
      final activated = await _activateChatSession(scope);
      if (!activated || !isAuthenticatedSessionScopeCurrent(ref, scope)) {
        return false;
      }

      final socketService = _socketService;
      if (socketService == null) return false;

      await socketService.sendMessage(
        chatId: chatId,
        message: trimmed,
        type: optimisticMessage.type,
        clientTempId: clientTempId,
      );

      if (!isAuthenticatedSessionScopeCurrent(ref, scope)) return false;

      _pendingConfirmationTimers[clientTempId]?.cancel();
      _pendingConfirmationTimers[clientTempId] = Timer(
        const Duration(seconds: 10),
        () {
          if (isAuthenticatedSessionScopeCurrent(ref, scope)) {
            markFailed(clientTempId);
          }
        },
      );

      return true;
    } catch (error) {
      if (isAuthenticatedSessionScopeCurrent(ref, scope)) {
        markFailed(clientTempId);
      }
      return false;
    }
  }

  Future<bool> retry(ChatMessageModel message) async {
    remove(message.id);

    return sendMessage(message.content);
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
      final next = await AsyncValue.guard(() async {
        final activated = await _activateChatSession(scope);
        if (!activated) {
          return const QueryState<ChatMessageModel>(itemsPerPage: 50, count: 0);
        }
        return _fetchPage(1, scope);
      });
      if (isAuthenticatedSessionScopeCurrent(ref, scope)) {
        _stateScope = scope;
        state = next;
      }
      return;
    }

    state = AsyncData(previous.copyWith(isRefreshing: true));
    try {
      final activated = await _activateChatSession(scope);
      if (!activated) return;
      final fresh = await _fetchPage(1, scope);
      if (isAuthenticatedSessionScopeCurrent(ref, scope)) {
        _stateScope = scope;
        final latest = state.value ?? previous;
        final mergedCount = fresh.count > latest.count
            ? fresh.count
            : latest.count;
        state = AsyncData(
          latest.copyWith(
            items: mergeMessages(latest.items, fresh.items),
            page: latest.page > fresh.page ? latest.page : fresh.page,
            itemsPerPage: fresh.itemsPerPage,
            count: mergedCount,
            lastFetchedAt: DateTime.now,
            isRefreshing: false,
            refreshError: () => null,
          ),
        );
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

    if (current == null) return;

    if (!current.hasMore) return;

    if (current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final result = await _fetchPage(current.page + 1, scope);
      if (!isAuthenticatedSessionScopeCurrent(ref, scope)) return;

      final latest = state.value ?? current;
      final mergedCount = result.count > latest.count
          ? result.count
          : latest.count;
      state = AsyncData(
        latest.copyWith(
          items: mergeMessages(latest.items, result.items),
          page: result.page > latest.page ? result.page : latest.page,
          itemsPerPage: result.itemsPerPage,
          count: mergedCount,
          lastFetchedAt: DateTime.now,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      if (isAuthenticatedSessionScopeCurrent(ref, scope)) {
        final latest = state.value ?? current;
        state = AsyncData(latest.copyWith(isLoadingMore: false));
      }
    }
  }

  void mergeFetchedMessages(List<ChatMessageModel> messages) {
    if (!_canMutateCurrentScope) return;
    final current = state.value;

    if (current == null) return;

    state = AsyncData(
      current.copyWith(items: mergeMessages(current.items, messages)),
    );
  }

  void mergeIncoming(ChatMessageModel message) {
    if (!_canMutateCurrentScope) return;
    final current = state.value;

    if (current == null) return;

    final items = mergeIncomingMessages(current.items, message);
    final added = items.length - current.items.length;

    state = AsyncData(
      current.copyWith(
        items: items,
        count: current.count + (added > 0 ? added : 0),
      ),
    );
  }

  Future<void> invalidate() async {
    if (!_canMutateCurrentScope) return;
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

    if (_stateScope != scope || current == null) {
      await refresh();
      return;
    }

    if (current.isStale) {
      await refresh();
    }
  }

  void insertPending(ChatMessageModel message) {
    if (!_canMutateCurrentScope) return;
    final current = state.value;

    if (current == null) return;

    final pending = message.copyWith(isPending: true, isFailed: false);

    state = AsyncData(
      current.copyWith(items: mergeIncomingMessages(current.items, pending)),
    );
  }

  bool replacePending(ChatMessageModel confirmed) {
    if (!_canMutateCurrentScope) return false;
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
    if (!_canMutateCurrentScope) return;
    final current = state.value;

    if (current == null) return;

    state = AsyncData(
      current.copyWith(
        items: current.items.where((e) => e.id != messageId).toList(),
      ),
    );
  }

  void markFailed(String clientTempId) {
    if (!_canMutateCurrentScope) return;
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
    if (!_canMutateCurrentScope) return;
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
    if (!_canMutateCurrentScope) return null;
    final current = state.value;

    if (current == null) return null;

    for (final message in current.items) {
      if (message.id == id) {
        return message;
      }
    }

    return null;
  }

  bool get _canMutateCurrentScope {
    final scope = readAuthenticatedSessionScope(ref);
    return scope != null && _stateScope == scope;
  }
}
