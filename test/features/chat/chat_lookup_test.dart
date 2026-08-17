import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/chat/models/chat_lookup.dart';
import 'package:prokat/features/chat/models/chat_model.dart';

void main() {
  test('ChatLookup.byId keys are value-equal', () {
    const first = ChatLookup.byId('chat-1');
    const second = ChatLookup.byId('chat-1');

    expect(first, equals(second));
    expect(first.hashCode, second.hashCode);
  });

  test('ChatLookup.byType keys are value-equal', () {
    const first = ChatLookup.byType(ChatType.support);
    const second = ChatLookup.byType(ChatType.support);

    expect(first, equals(second));
    expect(first.hashCode, second.hashCode);
  });

  test('ChatLookup keys with different payloads are not equal', () {
    expect(
      const ChatLookup.byId('chat-1'),
      isNot(equals(const ChatLookup.byId('chat-2'))),
    );
    expect(
      const ChatLookup.byType(ChatType.support),
      isNot(equals(const ChatLookup.byType(ChatType.workflow))),
    );
  });
}
