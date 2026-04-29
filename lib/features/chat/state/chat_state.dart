import 'package:prokat/features/chat/state/chat_message_model.dart';
import 'package:prokat/features/chat/state/chat_model.dart';

class ChatState {
  static const _unset = Object();

  final bool isLoadingConversations;
  final bool isLoadingMessages;

  final Set<String> sendingMessageClientTempIds;

  final String? error;

  final List<ChatModel> conversations;

  final ChatModel? currentChat;

  final List<ChatMessageModel> messages;

  final String? currentUserId;

  const ChatState({
    this.isLoadingConversations = false,
    this.isLoadingMessages = false,
    this.sendingMessageClientTempIds = const <String>{},
    this.error,
    this.conversations = const [],
    this.currentChat,
    this.messages = const [],
    this.currentUserId,
  });

  bool get isSendingMessage => sendingMessageClientTempIds.isNotEmpty;

  ChatState copyWith({
    bool? isLoadingConversations,
    bool? isLoadingMessages,
    Set<String>? sendingMessageClientTempIds,
    Object? error = _unset,
    List<ChatModel>? conversations,
    Object? currentChat = _unset,
    Object? messages = _unset,
    Object? currentUserId = _unset,
  }) {
    return ChatState(
      isLoadingConversations:
          isLoadingConversations ?? this.isLoadingConversations,
      isLoadingMessages: isLoadingMessages ?? this.isLoadingMessages,
      sendingMessageClientTempIds:
          sendingMessageClientTempIds ?? this.sendingMessageClientTempIds,
      error: identical(error, _unset) ? this.error : error as String?,
      conversations: conversations ?? this.conversations,
      currentChat: identical(currentChat, _unset)
          ? this.currentChat
          : currentChat as ChatModel?,
      messages: identical(messages, _unset)
          ? this.messages
          : messages as List<ChatMessageModel>,
      currentUserId: identical(currentUserId, _unset)
          ? this.currentUserId
          : currentUserId as String?,
    );
  }
}
