import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/auth/providers/auth_secure_storage.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/auth/providers/auth_state.dart';
import 'package:prokat/features/chat/state/chat_message_model.dart';
import 'package:prokat/features/chat/state/chat_model.dart';
import 'package:prokat/features/chat/state/chat_service.dart';
import 'package:prokat/features/chat/state/chat_socket_service.dart';
import 'package:prokat/features/chat/state/chat_state.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_provider.dart';
import 'package:prokat/features/chat/utils/chat_error_utils.dart';
import 'package:prokat/features/chat/utils/chat_message_utils.dart';
import 'package:prokat/features/chat/utils/chat_thread_utils.dart';

class ChatNotifier extends StateNotifier<ChatState> {
  final Ref ref;
  final ChatService service;
  final ChatSocketService socketService;
  final AuthSecureStorage secureStorage;
  String? _sessionToken;

  // Constructor
  ChatNotifier(this.ref, this.service, this.socketService, this.secureStorage)
    : super(const ChatState()) {
    _syncFromAuth(ref.read(authProvider));

    ref.listen<AuthState>(authProvider, (previous, next) {
      _syncFromAuth(next);
    });

    _loadSessionFallback();
    // getChatThreads("client");
  }

  @override
  void dispose() async {
    await socketService.disposeChatSession();
    super.dispose();
  }

  void _syncFromAuth(AuthState authState) {
    final session = authState.session;
    if (session == null) {
      return;
    }

    _sessionToken = session.sessionToken ?? _sessionToken ?? '';

    final user = session.user;
    final resolvedUserId =
        user?.id ?? user?.username ?? user?.phoneNumber ?? user?.displayName;

    if ((resolvedUserId ?? '').isNotEmpty) {
      state = state.copyWith(currentUserId: resolvedUserId);
    }
  }

  Future<void> _loadSessionFallback() async {
    final session = await secureStorage.readSession();

    _sessionToken = _sessionToken ?? session?.sessionToken ?? '';

    state = state.copyWith(
      currentUserId:
          session?.user?.id ??
          session?.user?.username ??
          session?.user?.phoneNumber ??
          session?.user?.displayName,
    );
  }

  Future<void> getChatThreads(String? mode) async {
    try {
      state = state.copyWith(isLoadingConversations: true, error: null);

      final result = await service.getChatThreads(mode);

      state = state.copyWith(
        isLoadingConversations: false,
        conversations: sortChats(result.data ?? []),
        error: null,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingConversations: false,
        error: friendlyChatError(error),
      );
    }
  }

  // Called when a chat is open, fetches the chat details, booking info, and messages
  Future<void> getChatById(String chatId) async {
    try {
      state = state.copyWith(isLoadingConversations: true, error: null);

      final result = await service.getChatById(chatId);

      if (result.success && result.data is ChatModel) {
        final messages = sortMessages(
          (result.data?.messages ?? []).take(50).toList(growable: false),
        );

        state = state.copyWith(
          isLoadingConversations: false,
          conversations: sortChats(
            upsertChat(state.conversations, result.data as ChatModel),
          ),
          currentChat: result.data,
          messages: messages,
          sendingMessageClientTempIds: const {},
          error: null,
        );
      } else {
        state = state.copyWith(
          isLoadingConversations: false,
          error: result.message,
        );
      }
    } catch (error) {
      state = state.copyWith(
        isLoadingConversations: false,
        error: friendlyChatError(error),
      );
    }
  }

  Future<void> openChatById(String chatId) async {
    final trimmedChatId = chatId.trim();

    if (trimmedChatId.isEmpty) return;

    try {
      state = state.copyWith(isLoadingMessages: true, error: null);

      if ((_sessionToken ?? '').isEmpty) {
        await _loadSessionFallback();
      }

      debugPrint('openChatById: loading chat $trimmedChatId');

      await getChatById(trimmedChatId);

      debugPrint('openChatById: connecting to chat room $trimmedChatId');

      await _connectToChat(trimmedChatId);

      debugPrint('openChatById: joined chat room $trimmedChatId');

      // Do this AFTER join, and do not allow it to block room join.
      try {
        await markCurrentChatAsRead();
      } catch (error) {
        debugPrint('markCurrentChatAsRead failed: $error');
      }

      state = state.copyWith(isLoadingMessages: false, error: null);
    } catch (error) {
      debugPrint('openChatById error: $error');

      state = state.copyWith(
        isLoadingMessages: false,
        error: friendlyChatError(error),
      );
    }
  }

  // Mark chat as read after it is open
  Future<void> markChatAsRead({
    required String chatId,
    required String messageId,
  }) async {
    try {
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

      await service.marckChatRead(chatId, messageId);
    } catch (error) {
      state = state.copyWith(
        isLoadingMessages: false,
        error: "Error loading chat",
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

    await markChatAsRead(chatId: chat.id, messageId: lastRealMessage.id);
  }

  // called on page refresh
  Future<void> reloadChat(String chatId) async {
    try {
      state = state.copyWith(isLoadingMessages: true, error: null);

      await getChatById(chatId);
      await markCurrentChatAsRead();

      final bookingId = state.currentChat?.booking?.id;

      if ((bookingId ?? '').isNotEmpty) {
        ref.invalidate(priceNegotiationByBookingProvider(bookingId!));
      }

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
      debugPrint("error_leaving_chat: $error");

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

    final currentUserId = state.currentUserId ?? 'me';
    final clientTempId = DateTime.now().microsecondsSinceEpoch.toString();

    final optimisticMessage = ChatMessageModel(
      id: clientTempId,
      chatId: chat.id,
      senderId: currentUserId,
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

  Future<void> _connectToChat(String chatId) async {
    if ((_sessionToken ?? '').isEmpty) {
      await _loadSessionFallback();
    }

    await socketService.connect(token: _sessionToken);

    print("connect_socket");

    socketService.onNewMessage(_handleIncomingMessage);

    await socketService.joinChat(chatId);
  }

  void _handleIncomingMessage(ChatMessageModel incoming) {
    final isCurrentChat = state.currentChat?.id == incoming.chatId;

    final cleanIncoming = incoming.copyWith(isPending: false, isFailed: false);

    final mergedMessages = isCurrentChat
        ? mergeMessages(state.messages, cleanIncoming)
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
      markChatAsRead(chatId: incoming.chatId, messageId: incoming.id);
    }

    // if (incoming.service == "PRICE_NEGOTIATION") {
    //   final bookingId = state.currentChat?.booking?.id;

    //   if ((bookingId ?? '').isNotEmpty) {
    //     ref.invalidate(priceNegotiationByBookingProvider(bookingId!));
    //   }
    // }
  }
}
