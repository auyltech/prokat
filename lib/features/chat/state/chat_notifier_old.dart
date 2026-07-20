import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/api/fetch_status.dart';
import 'package:prokat/core/errors/app_error.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/chat/models/chat_message_model.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/chat/service/chat_service.dart';
import 'package:prokat/features/chat/service/chat_socket_service.dart';
import 'package:prokat/features/chat/state/chat_state.dart';
import 'package:prokat/features/chat/utils/chat_error_utils.dart';
import 'package:prokat/features/chat/utils/chat_message_utils.dart';
import 'package:prokat/features/chat/utils/chat_thread_utils.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_provider.dart';

class ChatNotifier extends StateNotifier<ChatState> {
  final Ref ref;
  final ChatService service;
  final ChatSocketService socketService;

  // Constructor
  ChatNotifier(this.ref, this.service, this.socketService)
    : super(const ChatState());

  @override
  void dispose() async {
    await socketService.disposeChatSession();
    super.dispose();
  }

  void invalidate({required AppMode mode}) {
    state = state.copyWith(fetchStatus: FetchStatus.stale);
  }

  Future<void> getChatThreads(AppMode? mode) async {
    try {
      final hasData = state.conversations.isNotEmpty;

      state = state.copyWith(
        fetchStatus: hasData ? FetchStatus.refreshing : FetchStatus.loading,
        fetchError: null,
      );

      final result = await service.getClientChats(itemsPerPage: 20, page: 1);

      state = state.copyWith(
        conversations: sortChats(result.data?.items ?? []),
        fetchStatus: result.data == null
            ? FetchStatus.error
            : result.data?.items.isEmpty == true
            ? FetchStatus.empty
            : FetchStatus.success,
        lastFetchedAt: DateTime.now(),
        fetchError: result.success
            ? null
            : AppError(
                type: ErrorType.unknown,
                message: result.error.toString(),
                code: "CHAT_FETCH_FAILED",
              ),
      );
    } catch (error) {
      state = state.copyWith(
        fetchStatus: state.conversations.isEmpty
            ? FetchStatus.error
            : FetchStatus.stale,
        fetchError: AppError(
          type: ErrorType.unknown,
          message: friendlyChatError(error),
          code: "CHAT_FETCH_FAILED",
        ),
      );
    }
  }

  // Called when a chat is open, fetches the chat details, booking info, and messages
  Future<void> getChatById(String chatId) async {
    try {
      final hasData = state.conversations.isNotEmpty;

      state = state.copyWith(
        fetchStatus: hasData ? FetchStatus.refreshing : FetchStatus.loading,
        fetchError: null,
      );

      final result = await service.getChatById(chatId);

      final newIds = (result.data?.messages ?? []).map((item) => item.id);

      final existingMessages = state.messages.where(
        (item) => !newIds.contains((item.id)),
      );

      final newMessages = (result.data?.messages ?? [])
          .take(50)
          .toList(growable: false);

      final messages = sortMessages([...existingMessages, ...newMessages]);

      state = state.copyWith(
        conversations: sortChats(
          upsertChat(state.conversations, result.data as ChatModel),
        ),
        currentChat: result.data,
        messages: messages,
        sendingMessageClientTempIds: const {},
        fetchStatus: result.data == null
            ? FetchStatus.error
            : FetchStatus.success,
        fetchError: result.success
            ? null
            : AppError(
                type: ErrorType.unknown,
                message: result.error.toString(),
                code: "CHAT_FETCH_FAILED",
              ),
      );
    } catch (error) {
      state = state.copyWith(
        fetchStatus: state.conversations.isEmpty
            ? FetchStatus.error
            : FetchStatus.stale,
        fetchError: AppError(
          type: ErrorType.unknown,
          message: friendlyChatError(error),
          code: "CHAT_FETCH_FAILED",
        ),
      );
    }
  }

  Future<void> openChatById(String chatId) async {
    final trimmedChatId = chatId.trim();

    if (trimmedChatId.isEmpty) return;

    try {
      // 1. Find if this conversation exists in the user's fetched list
      final foundChat = state.conversations
          .where((item) => item.id == trimmedChatId)
          .firstOrNull;

      // 2. IDOR Prevention: Block access if the conversation is not found in their list
      // if (foundChat == null) {
      //   state = state.copyWith(
      //     isLoadingMessages: true,
      //     // error: "You do not have permission to view this chat.",
      //   );
      //   // Halt execution before calling backend or socket
      // }

      // final currentUserId = ref.read(authProvider).currentUserId;

      // if ((foundChat.client?.id != currentUserId) &&
      //     (foundChat.owner?.id != currentUserId)) {
      //   state = state.copyWith(
      //     isLoadingMessages: false,
      //     error: "You do not have permission to view this chat.",
      //   );
      //   return; // Halt execution before calling backend or socket
      // }

      state = state.copyWith(
        currentChat: foundChat,
        isLoadingMessages: true,
        error: null,
      );

      await getChatById(trimmedChatId);
      await connectToChat(trimmedChatId);

      // Do this AFTER join, and do not allow it to block room join.
      try {
        await markCurrentChatAsRead();
      } finally {}

      state = state.copyWith(isLoadingMessages: false, error: null);
    } catch (error) {
      state = state.copyWith(
        isLoadingMessages: false,
        error: friendlyChatError(error),
      );
    }
  }

  // helper function to get current chatId and mark as read
  Future<void> markCurrentChatAsRead() async {
    final chat = state.currentChat;

    if (chat == null) {
      return;
    }

    final lastRealMessage = state.messages
        .where((message) => message.id.isNotEmpty && !message.isPending)
        .toList(growable: false)
        .firstOrNull;

    if (lastRealMessage == null) {
      return;
    }

    // await markChatAsRead(chatId: chat.id, messageId: lastRealMessage.id);
  }

  // called on page refresh
  Future<void> reloadChat(String chatId) async {
    try {
      if (state.isLoadingConversations || state.isLoadingMessages) return;

      state = state.copyWith(isLoadingMessages: true, error: null);

      await getChatById(chatId);
      await ref.read(priceNegotiationProvider.notifier).getPriceNegotiations();
      await markCurrentChatAsRead();

      state = state.copyWith(
        isLoadingMessages: false,
        sendingMessageClientTempIds: const {},
        error: null,
        isLoadingConversations: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingMessages: false,
        error: "Error loading chat",
      );
    }
  }

  // called when user goes out of the chat/:id screen (with back button)
  // leaveCurrentChat()
  // → leave active chat room
  // → remove chat message listener
  // → clear current chat UI state
  // → keep base socket alive for app-level notifications later
  Future<void> leaveCurrentChat() async {
    try {
      await socketService.disposeChatSession();

      state = state.copyWith(
        currentChat: null,
        messages: const [],
        sendingMessageClientTempIds: const {},
        isLoadingMessages: false,
        error: null,
      );
    } catch (error) {
      state = state.copyWith(
        currentChat: null,
        messages: const [],
        sendingMessageClientTempIds: const {},
        isLoadingMessages: false,
        error: null,
      );
    }
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    final chat = state.currentChat;

    if (chat == null || trimmed.isEmpty) {
      return;
    }

    final session = ref.read(authProvider).session;
    final senderId = session?.user?.id;

    if (senderId == null || senderId.isEmpty) {
      return;
    }

    final clientTempId = DateTime.now().microsecondsSinceEpoch.toString();

    final optimisticMessage = ChatMessageModel(
      id: clientTempId,
      chatId: chat.id,
      senderId: senderId,
      senderName: 'You',
      content: trimmed,
      type: 'TEXT',
      clientTempId: clientTempId,
      isPending: true,
      isFailed: false,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      sendingMessageClientTempIds: {
        ...state.sendingMessageClientTempIds,
        clientTempId,
      },
      messages: [optimisticMessage, ...state.messages],
      currentChat: chat.copyWith(lastMessage: optimisticMessage),
      conversations: mergeChatPreview(
        chats: state.conversations,
        chatId: chat.id,
        message: optimisticMessage,
      ),
      error: null,
    );

    try {
      socketService.sendMessage(
        chatId: chat.id,
        message: trimmed,
        type: optimisticMessage.type,
        clientTempId: clientTempId,
      );
    } catch (error) {
      _markMessageAsFailed(clientTempId, error);
    }
  }

  Future<void> sendSupportMessage(String content, AppMode? mode) async {
    try {
      final trimmed = content.trim();

      final clientTempId = DateTime.now().microsecondsSinceEpoch.toString();

      final session = ref.read(authProvider).session;
      final senderId = session?.user?.id;

      if (senderId == null || senderId.isEmpty) {
        return;
      }

      final optimisticMessage = ChatMessageModel(
        id: clientTempId,
        chatId: "support",
        senderId: senderId,
        senderName: 'You',
        content: trimmed,
        type: 'TEXT',
        clientTempId: clientTempId,
        isPending: true,
        isFailed: false,
        createdAt: DateTime.now(),
      );

      state = state.copyWith(
        sendingMessageClientTempIds: {
          ...state.sendingMessageClientTempIds,
          clientTempId,
        },
        messages: [optimisticMessage, ...state.messages],
        error: null,
      );

      final result = await service.sendChatMessage(
        chatId: "support",
        content: trimmed,
        type: "TEXT",
        clientTempId: clientTempId,
      );

      if (result.success) {
        getChatThreads(mode);
      }
    } finally {}
  }

  void _markMessageAsFailed(String clientTempId, Object error) {
    state = state.copyWith(
      sendingMessageClientTempIds: {...state.sendingMessageClientTempIds}
        ..remove(clientTempId),
      error: friendlyChatError(error),
      messages: state.messages
          .map(
            (message) => message.clientTempId == clientTempId
                ? message.copyWith(isPending: false, isFailed: true)
                : message,
          )
          .toList(growable: false),
    );
  }

  Future<void> connectToChat(String chatId) async {
    final session = ref.read(authProvider).session;
    final sessionToken = session?.sessionToken;

    if (sessionToken == null || sessionToken.isEmpty) {
      return;
    }

    await socketService.connect();

    socketService.onNewMessage(_handleIncomingMessage);

    await socketService.joinChat(chatId);
  }

  void _handleIncomingMessage(ChatMessageModel incoming) {
    final isCurrentChat = state.currentChat?.id == incoming.chatId;

    final cleanIncoming = incoming.copyWith(isPending: false, isFailed: false);

    final mergedMessages = isCurrentChat
        ? mergeMessages(state.messages, [cleanIncoming])
        : state.messages;

    final updatedConversations = mergeChatPreview(
      chats: state.conversations,
      chatId: incoming.chatId,
      message: cleanIncoming,
    );

    final currentChat = isCurrentChat
        ? (state.currentChat ?? ChatModel(id: incoming.chatId)).copyWith(
            lastMessage: cleanIncoming,
          )
        : state.currentChat;

    final newMessages = mergedMessages
        .where((message) {
          final clientTempId = message.clientTempId?.trim() ?? '';
          return message.isPending && clientTempId.isNotEmpty;
        })
        .map((message) => message.clientTempId!.trim())
        .toSet();

    state = state.copyWith(
      messages: mergedMessages,
      conversations: updatedConversations,
      currentChat: currentChat,
      sendingMessageClientTempIds: newMessages,
      error: null,
    );

    if (isCurrentChat && incoming.id.isNotEmpty) {
      // markChatAsRead(chatId: incoming.chatId, messageId: incoming.id);
    }
  }
}
