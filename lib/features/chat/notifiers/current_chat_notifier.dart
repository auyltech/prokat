import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/chat/providers/chat_providers.dart';
import 'package:prokat/features/chat/models/chat_message_model.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/chat/service/chat_service.dart';

class CurrentChatNotifier extends FamilyAsyncNotifier<ChatModel?, String> {
  late final ChatService api;

  late final String _chatId;
  DateTime? _lastFetchedAt;
  Future<void>? _refreshing;

  @override
  Future<ChatModel?> build(String chatId) async {
    api = ref.read(chatServiceProvider);

    _chatId = chatId;

    return _fetch();
  }

  Future<ChatModel?> _fetch() async {
    final response = await api.getChatById(_chatId);

    if (!response.success || response.data == null) {
      throw Exception(response.message);
    }

    _lastFetchedAt = DateTime.now();
    return response.data;
  }

  Future<void> refresh() {
    final active = _refreshing;
    if (active != null) return active;
    final operation = _refresh();
    _refreshing = operation;
    return operation.whenComplete(() => _refreshing = null);
  }

  Future<void> _refresh() async {
    final hadData = state is AsyncData<ChatModel?>;
    final previous = state.value;
    if (!hadData && state.isLoading) {
      try {
        await future;
        return;
      } catch (_) {}
    }
    if (!hadData) {
      state = const AsyncLoading();
      state = await AsyncValue.guard(_fetch);
      return;
    }
    try {
      state = AsyncData(await _fetch());
    } catch (_) {
      state = AsyncData(previous);
    }
  }

  Future<void> refreshAll() async {
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
    if (state.isLoading) {
      try {
        await future;
      } catch (_) {}
    }
    final fetchedAt = _lastFetchedAt;
    if (fetchedAt == null ||
        DateTime.now().difference(fetchedAt) >= staleAfter) {
      await refresh();
    }
  }

  void invalidate() => _lastFetchedAt = null;

  Future<void> markRead({required String messageId}) async {
    final chat = state.value;

    if (chat == null) {
      return;
    }

    final response = await api.markChatRead(
      chatId: chat.id,
      messageId: messageId,
    );

    if (!response.success) {
      return;
    }

    state = AsyncData(
      chat.copyWith(
        // newMessagesCount: 0,
      ),
    );
  }

  void setChat(ChatModel chat) {
    state = AsyncData(chat);
  }

  void setLastMessage(ChatMessageModel message) {
    final chat = state.value;

    if (chat == null) {
      return;
    }

    state = AsyncData(
      chat.copyWith(lastMessage: message, updatedAt: message.createdAt),
    );
  }

  void closeChat() {
    final chat = state.value;

    if (chat == null) {
      return;
    }

    state = AsyncData(chat.copyWith(status: ChatStatus.closed));
  }

  void archiveChat() {
    final chat = state.value;

    if (chat == null) {
      return;
    }

    state = AsyncData(chat.copyWith(status: ChatStatus.archived));
  }
}
