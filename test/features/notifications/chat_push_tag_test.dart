import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/notifications/utils/chat_push_tag.dart';

void main() {
  test('builds a stable Android tag from chat id', () {
    expect(
      chatPushTag('cmsx8u5yc00001wni64bf560b'),
      'prokat.chat.cmsx8u5yc00001wni64bf560b',
    );
  });

  test('matches an active notification by tag', () {
    expect(
      displayedNotificationMatchesChat(
        chatId: 'chat-1',
        tag: chatPushTag('chat-1'),
      ),
      isTrue,
    );
  });

  test('does not match a notification from another chat', () {
    expect(
      displayedNotificationMatchesChat(
        chatId: 'chat-1',
        tag: chatPushTag('chat-2'),
        payload: '{"chatId":"chat-2"}',
      ),
      isFalse,
    );
  });

  test('matches a local notification payload that contains the chat id', () {
    expect(
      displayedNotificationMatchesChat(
        chatId: 'chat-1',
        payload: '{"data":{"chatId":"chat-1"}}',
      ),
      isTrue,
    );
  });
}
