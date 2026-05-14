import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/auth/providers/auth_secure_storage.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/auth/providers/auth_state.dart';
import 'package:prokat/features/chat/state/chat_message_model.dart';
import 'package:prokat/features/chat/state/chat_model.dart';
import 'package:prokat/features/chat/state/chat_service.dart';
import 'package:prokat/features/chat/state/chat_socket_service.dart';
import 'package:prokat/features/chat/state/chat_state.dart';

bool _withinThirtySeconds(DateTime? first, DateTime? second) {
  if (first == null || second == null) {
    return false;
  }

  return first.difference(second).inSeconds.abs() <= 30;
}

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
  void dispose() {
    socketService.disconnect();
    super.dispose();
  }

  ChatModel? _findConversationById(String chatId) {
    for (final chat in state.conversations) {
      if (chat.id == chatId) {
        return chat;
      }
    }
    return null;
  }

  List<ChatModel> _sortConversations(List<ChatModel> conversations) {
    final sorted = List<ChatModel>.from(conversations);
    sorted.sort((a, b) {
      final aDate =
          a.lastMessage?.createdAt ??
          a.updatedAt ??
          a.createdAt ??
          DateTime(1970);
      final bDate =
          b.lastMessage?.createdAt ??
          b.updatedAt ??
          b.createdAt ??
          DateTime(1970);
      return bDate.compareTo(aDate);
    });
    return sorted;
  }

  List<ChatModel> _upsertChat(List<ChatModel> chats, ChatModel chat) {
    final index = chats.indexWhere((item) => item.id == chat.id);

    if (index == -1) {
      return [chat, ...chats];
    }

    final updated = [...chats];
    updated[index] = chat;
    return updated;
  }

  void _syncFromAuth(AuthState authState) {
    final session = authState.session;
    if (session == null) {
      return;
    }

    _sessionToken = session.sessionToken ?? _sessionToken ?? '';

    final user = session.user;
    final resolvedUserId =
        user?.id ?? user?.username ?? user?.phone ?? user?.displayName;

    if ((resolvedUserId ?? '').isNotEmpty) {
      state = state.copyWith(currentUserId: resolvedUserId);
    }
  }

  Future<void> _loadSessionFallback() async {
    final session = await secureStorage.readSession();

    print(session);

    _sessionToken = _sessionToken ?? session?.sessionToken ?? '';

    state = state.copyWith(
      currentUserId:
          session?.user?.id ??
          session?.user?.username ??
          session?.user?.phone ??
          session?.user?.displayName,
    );
  }

  Future<void> getChatThreads(String? mode) async {
    try {
      state = state.copyWith(isLoadingConversations: true, error: null);

      final conversations = await service.getChatThreads(mode);

      state = state.copyWith(
        isLoadingConversations: false,
        conversations: _sortConversations(conversations),
        error: null,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingConversations: false,
        error: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> openChatById(String chatId) async {
    try {
      if ((_sessionToken ?? '').isEmpty) {
        await _loadSessionFallback();
      }

      final knownChat = _findConversationById(chatId);

      if (knownChat == null) {
        state = state.copyWith(
          currentChat: ChatModel(id: chatId),
          isLoadingMessages: false,
          messages: const <ChatMessageModel>[],
          error: "Error loading chat",
        );
      }

      state = state.copyWith(
        currentChat: knownChat ?? ChatModel(id: chatId),
        isLoadingMessages: true,
        messages: const <ChatMessageModel>[],
        error: null,
      );

      final chatDetails = await service.getChatById(chatId);

      if (chatDetails == null) {
        throw Exception('Chat not found');
      }

      final messages = _sortMessages(
        chatDetails.messages.take(50).toList(growable: false),
      );

      state = state.copyWith(
        conversations: _upsertChat(state.conversations, chatDetails),
        currentChat: chatDetails,
        messages: messages,
        isLoadingMessages: false,
      );

      await _connectToChat(chatId);
    } catch (error) {
      state = state.copyWith(
        isLoadingMessages: false,
        error: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> reloadChat(String chatId) async {
    try {
      final chatDetails = await service.getChatById(chatId);

      state = state.copyWith(currentChat: chatDetails);
    } catch (err) {
      state = state.copyWith(error: "Error loading order");
    }
  }

  Future<void> leaveCurrentChat() async {
    final currentChatId = state.currentChat?.id;
    if ((currentChatId ?? '').isNotEmpty) {
      socketService.leaveChat(currentChatId!);
    }

    socketService.disconnect();
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    final chat = state.currentChat;
    if (chat == null || trimmed.isEmpty) {
      return;
    }

    final currentUserId = state.currentUserId ?? 'me';
    final clientTempId = DateTime.now().microsecondsSinceEpoch.toString();
    final updatedSendingIds = {...state.sendingMessageClientTempIds}
      ..add(clientTempId);

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
      sendingMessageClientTempIds: updatedSendingIds,
      messages: [optimisticMessage, ...state.messages],
      currentChat: chat.copyWith(lastMessage: optimisticMessage),
      conversations: _mergeConversationPreview(
        chatId: chat.id,
        message: optimisticMessage,
      ),
      error: null,
    );

    try {
      await _connectToChat(chat.id);
      socketService.sendMessage(
        chatId: chat.id,
        message: trimmed,
        type: optimisticMessage.type,
        clientTempId: clientTempId,
      );
    } catch (error) {
      final failedSendingIds = {...state.sendingMessageClientTempIds}
        ..remove(clientTempId);
      state = state.copyWith(
        sendingMessageClientTempIds: failedSendingIds,
        error: error.toString().replaceFirst('Exception: ', ''),
        messages: state.messages
            .map(
              (message) => message.clientTempId == clientTempId
                  ? message.copyWith(isPending: false, isFailed: true)
                  : message,
            )
            .toList(growable: false),
      );
    }
  }

  Future<String?> getChatId({String? bookingId, String? requestId, String? mode}) async {
    final normalizedBookingId = (bookingId ?? '').trim();
    final normalizedRequestId = (requestId ?? '').trim();

    if (normalizedBookingId.isEmpty && normalizedRequestId.isEmpty) {
      return null;
    }

    final localMatch = state.conversations.firstWhere(
      (chat) =>
          (normalizedBookingId.isNotEmpty &&
              chat.bookingId == normalizedBookingId) ||
          (normalizedRequestId.isNotEmpty &&
              chat.requestId == normalizedRequestId),
      orElse: () => const ChatModel(id: ''),
    );

    if (localMatch.id.isNotEmpty) {
      return localMatch.id;
    }

    try {
      final resolvedId = await service.getChatId(
        bookingId: normalizedBookingId.isEmpty ? null : normalizedBookingId,
        requestId: normalizedRequestId.isEmpty ? null : normalizedRequestId,
      );

      await getChatThreads(mode);
      return resolvedId;
    } catch (error) {
      state = state.copyWith(
        error: error.toString().replaceFirst('Exception: ', ''),
      );
      return null;
    }
  }

  Future<void> _connectToChat(String chatId) async {
    if ((_sessionToken ?? '').isEmpty) {
      await _loadSessionFallback();
    }

    await socketService.connect(token: _sessionToken);
    socketService.onNewMessage(_handleIncomingMessage);
    await socketService.joinChat(chatId);
  }

  void _handleIncomingMessage(ChatMessageModel incoming) {
    final isCurrentChat = state.currentChat?.id == incoming.chatId;
    final mergedMessages = isCurrentChat
        ? _mergeMessages(state.messages, incoming)
        : state.messages;
    final nextSendingIds = mergedMessages
        .where((m) => m.isPending && (m.clientTempId ?? '').trim().isNotEmpty)
        .map((m) => m.clientTempId!.trim())
        .toSet();

    final updatedConversations = _mergeConversationPreview(
      chatId: incoming.chatId,
      message: incoming.copyWith(isPending: false),
    );

    final currentChat = state.currentChat?.id == incoming.chatId
        ? (state.currentChat ?? ChatModel(id: incoming.chatId)).copyWith(
            lastMessage: incoming.copyWith(isPending: false),
          )
        : state.currentChat;

    state = state.copyWith(
      messages: mergedMessages,
      conversations: updatedConversations,
      currentChat: currentChat,
      sendingMessageClientTempIds: nextSendingIds,
      error: null,
    );
  }

  List<ChatModel> _mergeConversationPreview({
    required String chatId,
    required ChatMessageModel message,
  }) {
    final current = List<ChatModel>.from(state.conversations);
    final index = current.indexWhere((chat) => chat.id == chatId);

    if (index == -1) {
      current.insert(
        0,
        ChatModel(
          id: chatId,
          lastMessage: message.copyWith(isPending: false),
          updatedAt: message.createdAt ?? DateTime.now(),
        ),
      );
      return _sortConversations(current);
    }

    final updated = current[index].copyWith(
      lastMessage: message.copyWith(isPending: false),
      updatedAt: message.createdAt ?? DateTime.now(),
    );
    current
      ..removeAt(index)
      ..insert(0, updated);

    return _sortConversations(current);
  }

  List<ChatMessageModel> _mergeMessages(
    List<ChatMessageModel> existing,
    ChatMessageModel incoming,
  ) {
    final updated = List<ChatMessageModel>.from(existing);

    final exactIndex = updated.indexWhere(
      (message) => message.id.isNotEmpty && message.id == incoming.id,
    );
    if (exactIndex != -1) {
      updated[exactIndex] = incoming.copyWith(
        isPending: false,
        isFailed: false,
      );
      return _sortMessages(updated);
    }

    final tempIndex = updated.indexWhere(
      (message) =>
          (message.clientTempId ?? '').isNotEmpty &&
          message.clientTempId == incoming.clientTempId,
    );
    if (tempIndex != -1) {
      updated[tempIndex] = incoming.copyWith(isPending: false, isFailed: false);
      return _sortMessages(updated);
    }

    final fallbackPendingIndex = updated.indexWhere(
      (message) =>
          message.isPending &&
          message.senderId == incoming.senderId &&
          message.content.trim() == incoming.content.trim() &&
          _withinThirtySeconds(message.createdAt, incoming.createdAt),
    );
    if (fallbackPendingIndex != -1) {
      updated[fallbackPendingIndex] = incoming.copyWith(
        isPending: false,
        isFailed: false,
      );
      return _sortMessages(updated);
    }

    updated.insert(0, incoming.copyWith(isPending: false, isFailed: false));
    return _sortMessages(updated);
  }

  List<ChatMessageModel> _sortMessages(List<ChatMessageModel> messages) {
    final sorted = List<ChatMessageModel>.from(messages);
    sorted.sort((a, b) {
      final aDate = a.createdAt ?? DateTime(1970);
      final bDate = b.createdAt ?? DateTime(1970);
      return bDate.compareTo(aDate);
    });
    return sorted;
  }
}
