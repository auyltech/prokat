import 'package:prokat/features/chat/state/chat_message_model.dart';
import 'package:prokat/features/chat/state/chat_model.dart';

DateTime chatSortDate(ChatModel chat) {
  return chat.lastMessage?.createdAt ??
      chat.updatedAt ??
      chat.createdAt ??
      DateTime(1970);
}

List<ChatModel> sortChats(List<ChatModel> chats) {
  final sorted = List<ChatModel>.from(chats);

  sorted.sort((a, b) {
    return chatSortDate(b).compareTo(chatSortDate(a));
  });

  return sorted;
}

List<ChatModel> upsertChat(List<ChatModel> chats, ChatModel chat) {
  final index = chats.indexWhere((item) => item.id == chat.id);

  if (index == -1) {
    return sortChats([chat, ...chats]);
  }

  final updated = List<ChatModel>.from(chats);
  updated[index] = chat;

  return sortChats(updated);
}

List<ChatModel> mergeChatPreview({
  required List<ChatModel> chats,
  required String chatId,
  required ChatMessageModel message,
}) {
  final current = List<ChatModel>.from(chats);
  final index = current.indexWhere((chat) => chat.id == chatId);

  final cleanMessage = message.copyWith(isPending: false);

  if (index == -1) {
    current.insert(
      0,
      ChatModel(
        id: chatId,
        lastMessage: cleanMessage,
        updatedAt: message.createdAt ?? DateTime.now(),
      ),
    );

    return sortChats(current);
  }

  final updatedChat = current[index].copyWith(
    lastMessage: cleanMessage,
    updatedAt: message.createdAt ?? DateTime.now(),
  );

  current[index] = updatedChat;

  return sortChats(current);
}