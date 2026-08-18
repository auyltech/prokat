import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/chat/models/chat_message_model.dart';
import 'package:prokat/features/chat/utils/chat_message_utils.dart';

void main() {
  ChatMessageModel message({required String id, required DateTime createdAt}) {
    return ChatMessageModel(
      id: id,
      chatId: 'chat-1',
      senderId: 'user-1',
      content: id,
      createdAt: createdAt,
    );
  }

  test('sortMessages keeps newest messages first for page 1', () {
    final older = message(id: 'old', createdAt: DateTime(2026, 8, 18, 10));
    final newer = message(id: 'new', createdAt: DateTime(2026, 8, 18, 12));

    final sorted = sortMessages([older, newer]);

    expect(sorted.map((item) => item.id), ['new', 'old']);
  });

  test('mergeMessages prepends older page items after the newest ones', () {
    final newest = message(id: 'p1-new', createdAt: DateTime(2026, 8, 18, 12));
    final pageOneOld = message(
      id: 'p1-old',
      createdAt: DateTime(2026, 8, 18, 11),
    );
    final pageTwo = message(id: 'p2', createdAt: DateTime(2026, 8, 18, 9));

    final merged = mergeMessages([newest, pageOneOld], [pageTwo]);

    expect(merged.map((item) => item.id), ['p1-new', 'p1-old', 'p2']);
  });

  test('mergeMessages keeps a newly received message at index 0', () {
    final older = message(id: 'old', createdAt: DateTime(2026, 8, 18, 10));
    final incoming = message(id: 'new', createdAt: DateTime(2026, 8, 18, 13));

    final merged = mergeMessages([older], [incoming]);

    expect(merged.first.id, 'new');
  });
}
