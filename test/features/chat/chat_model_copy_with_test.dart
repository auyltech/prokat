import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/chat/models/chat_message_model.dart';
import 'package:prokat/features/chat/models/chat_model.dart';

void main() {
  group('ChatModel.copyWith', () {
    test('retains newMessagesCount when lastMessage is updated', () {
      final chat = ChatModel(id: 'chat-1', newMessagesCount: 3);
      const lastMessage = ChatMessageModel(
        id: 'msg-1',
        chatId: 'chat-1',
        senderId: 'user-2',
        content: 'hello',
      );

      final updated = chat.copyWith(lastMessage: lastMessage);

      expect(updated.newMessagesCount, 3);
      expect(updated.lastMessage, same(lastMessage));
    });

    test('updates newMessagesCount when a value is passed', () {
      final chat = ChatModel(id: 'chat-1', newMessagesCount: 3);

      final updated = chat.copyWith(newMessagesCount: 0);

      expect(updated.newMessagesCount, 0);
    });
  });
}
