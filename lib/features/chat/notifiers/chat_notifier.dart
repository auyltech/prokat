import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/chat/providers/chat_providers.dart';
import 'package:prokat/features/chat/models/chat_message_model.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/chat/service/chat_service.dart';

class ChatNotifier extends FamilyAsyncNotifier<ChatModel, String> {
  late final ChatService api;

  late final String _chatId;

  @override
  Future<ChatModel> build(String chatId) async {
    api = ref.read(chatServiceProvider);
    _chatId = chatId;

    return _fetch();
  }

  Future<ChatModel> _fetch() async {
    final response = await api.getChatById(_chatId);

    if (!response.success || response.data == null) {
      throw Exception(response.message);
    }

    return response.data!;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(_fetch);
  }

  Future<void> refreshAll() async {
    await refresh();
    await ref.read(chatMessagesProvider(_chatId).notifier).refresh();
  }

  Future<void> refreshIfStale({
    Duration staleAfter = const Duration(minutes: 5),
  }) async {
    final lastUpdated = state.value?.updatedAt;

    if (lastUpdated == null) {
      await refresh();
      return;
    }

    if (DateTime.now().difference(lastUpdated) >= staleAfter) {
      await refresh();
    }
  }

  Future<void> invalidate() async {
    await refresh();
  }

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
