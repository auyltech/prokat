import 'package:prokat/core/utils/parse.dart';
import 'package:prokat/features/chat/models/chat_message_model.dart';

class ChatSidebarUpdate {
  final String chatId;
  final ChatMessageModel? lastMessage;
  final int? unreadCount;

  const ChatSidebarUpdate({
    required this.chatId,
    this.lastMessage,
    this.unreadCount,
  });

  static ChatSidebarUpdate? tryParse(dynamic payload) {
    final json = _asStringKeyedMap(payload);
    if (json == null) return null;

    final chatId = json['chatId']?.toString().trim() ?? '';
    if (chatId.isEmpty) return null;

    var lastMessage = _parseMessage(json['lastMessage']);
    if (lastMessage != null && lastMessage.chatId.trim().isEmpty) {
      lastMessage = lastMessage.copyWith(chatId: chatId);
    }

    final unreadCount = parseNullableInt(json['unreadCount']);

    if (lastMessage == null && unreadCount == null) {
      return null;
    }

    return ChatSidebarUpdate(
      chatId: chatId,
      lastMessage: lastMessage,
      unreadCount: unreadCount,
    );
  }

  static ChatMessageModel? _parseMessage(dynamic value) {
    final json = _asStringKeyedMap(value);
    if (json == null) return null;
    return ChatMessageModel.fromJson(json);
  }

  static Map<String, dynamic>? _asStringKeyedMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }
}
