import 'package:prokat/features/chat/models/chat_model.dart';

class ChatLookup {
  final String? chatId;
  final ChatType? type;

  const ChatLookup.byId(this.chatId) : type = null;

  const ChatLookup.byType(this.type) : chatId = null;
}
