import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/chat/models/chat_message_model.dart';
import 'package:prokat/features/chat/models/chat_model.dart';

void main() {
  group('ChatModel.copyWith', () {
    test('server inquiry with no booking keeps a nullable booking id', () {
      for (final value in [null, '', '  ']) {
        final chat = ChatModel.fromJson({
          'id': 'inquiry-chat',
          'bookingId': value,
          'inquiryEquipmentId': 'equipment-1',
        });
        expect(chat.bookingId, isNull);
        expect(chat.copyWith(lastMessage: null).bookingId, isNull);
      }
      expect(
        ChatModel.fromJson({'id': 'chat', 'bookingId': 'booking-1'}).bookingId,
        'booking-1',
      );
    });
    test('retains newMessagesCount when lastMessage is updated', () {
      const chat = ChatModel(id: 'chat-1', newMessagesCount: 3);
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
      const chat = ChatModel(id: 'chat-1', newMessagesCount: 3);

      final updated = chat.copyWith(newMessagesCount: 0);

      expect(updated.newMessagesCount, 0);
    });
  });
}
