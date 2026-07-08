import 'package:prokat/core/api/fetch_status.dart';
import 'package:prokat/core/errors/app_error.dart';
import 'package:prokat/core/mutation/mutation_model.dart';
import 'package:prokat/features/chat/state/chat_message_model.dart';
import 'package:prokat/features/chat/state/chat_model.dart';

class ChatState {
  final FetchStatus fetchStatus;
  final PaginationStatus paginationStatus;

  final DateTime? lastFetchedAt;
  final AppError? fetchError;

  final Set<Mutation> activeActions;

  static const _unset = Object();

  final bool isLoadingConversations;
  final bool isLoadingMessages;

  final String? error;

  final List<ChatModel> conversations;
  final ChatModel? currentChat;
  final List<ChatMessageModel> messages;

  final Set<String> sendingMessageClientTempIds;

  bool get isLoading {
    return fetchStatus == FetchStatus.loading ||
        fetchStatus == FetchStatus.refreshing;
  }

  const ChatState({
    this.fetchStatus = FetchStatus.initial,
    this.paginationStatus = PaginationStatus.idle,
    this.lastFetchedAt,
    this.fetchError,
    this.activeActions = const {},

    this.isLoadingConversations = false,
    this.isLoadingMessages = false,
    this.sendingMessageClientTempIds = const <String>{},
    this.error,
    this.conversations = const [],
    this.currentChat,
    this.messages = const [],
  });

  bool get isSendingMessage => sendingMessageClientTempIds.isNotEmpty;

  ChatState copyWith({
    FetchStatus? fetchStatus,
    PaginationStatus? paginationStatus,
    DateTime? lastFetchedAt,
    AppError? fetchError,
    Set<Mutation>? activeActions,

    bool? isLoadingConversations,
    bool? isLoadingMessages,
    Set<String>? sendingMessageClientTempIds,
    Object? error = _unset,
    List<ChatModel>? conversations,
    Object? currentChat = _unset,
    Object? messages = _unset,
  }) {
    return ChatState(
      fetchStatus: fetchStatus ?? this.fetchStatus,
      paginationStatus: paginationStatus ?? this.paginationStatus,
      lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
      fetchError: fetchError,
      activeActions: activeActions ?? this.activeActions,

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
    );
  }
}
