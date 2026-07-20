import 'package:prokat/features/chat/models/chat_message_model.dart';
import 'package:prokat/core/services/app_socket_service.dart';

class ChatSocketService {
  static const String joinChatEvent = 'chat:join';
  static const String leaveChatEvent = 'chat:leave';
  static const String sendMessageEvent = 'chat:message:send';
  static const String newMessageEvent = 'chat:message:new';

  final AppSocketService appSocket;

  String? _joinedChatId;

  ChatSocketService(this.appSocket);

  Future<void> connect() async {
    await appSocket.connect();
  }

  // Send Message
  void sendMessage({
    required String chatId,
    required String message,
    required String type,
    String? clientTempId,
  }) {
    appSocket.emit(sendMessageEvent, {
      'chatId': chatId,
      'type': type,
      'content': message,
      if ((clientTempId ?? '').isNotEmpty) 'clientTempId': clientTempId,
    });
  }

  // Receive Message
  void onNewMessage(void Function(ChatMessageModel message) handler) {
    appSocket.on(newMessageEvent, (payload) {
      if (payload is Map<String, dynamic>) {
        handler(ChatMessageModel.fromJson(payload));
        return;
      }

      if (payload is Map) {
        handler(ChatMessageModel.fromJson(Map<String, dynamic>.from(payload)));
      }
    });
  }

  Future<void> joinChat(String chatId) async {
    if (_joinedChatId == chatId) {
      return;
    }

    if ((_joinedChatId ?? '').isNotEmpty) {
      try {
        await leaveChat(_joinedChatId!);
      } finally {}
    }

    appSocket.emit(joinChatEvent, {'chatId': chatId});

    _joinedChatId = chatId;
  }

  Future<void> leaveChat(String chatId) async {
    final trimmedChatId = chatId.trim();

    if (trimmedChatId.isEmpty) return;

    final response = await appSocket.emitWithAck('chat:leave', {
      'chatId': trimmedChatId,
    });

    final success = response is Map && response['success'] == true;

    if (!success) {
      throw Exception(
        response is Map
            ? response['message'] ?? 'Failed to leave chat'
            : 'Failed to leave chat',
      );
    }

    if (_joinedChatId == trimmedChatId) {
      _joinedChatId = null;
    }
  }

  // Leave current chat room + remove chat listeners.
  Future<void> disposeChatSession() async {
    final chatId = _joinedChatId;

    if ((chatId ?? '').trim().isNotEmpty) {
      try {
        await leaveChat(chatId!);
      } finally {}
    }

    _joinedChatId = null;
    appSocket.off(newMessageEvent);
  }
}
