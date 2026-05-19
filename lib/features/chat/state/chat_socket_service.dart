import 'package:prokat/features/chat/state/chat_message_model.dart';
import 'package:prokat/core/services/app_socket_service.dart';

class ChatSocketService {
  static const String joinChatEvent = 'chat:join';
  static const String leaveChatEvent = 'chat:leave';
  static const String sendMessageEvent = 'chat:message:send';
  static const String newMessageEvent = 'chat:message:new';

  final AppSocketService appSocket;

  String? _joinedChatId;

  ChatSocketService(this.appSocket);

  Future<void> connect({String? token}) async {
    await appSocket.connect(token: token);
  }

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
      leaveChat(_joinedChatId!);
    }

    appSocket.emit(joinChatEvent, {'chatId': chatId});
    _joinedChatId = chatId;
  }

  void leaveChat(String chatId) {
    appSocket.emit(leaveChatEvent, {'chatId': chatId});
    if (_joinedChatId == chatId) {
      _joinedChatId = null;
    }
  }

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

  void disconnect() {
    if ((_joinedChatId ?? '').isNotEmpty) {
      leaveChat(_joinedChatId!);
    }

    appSocket.off(newMessageEvent);
  }
}
