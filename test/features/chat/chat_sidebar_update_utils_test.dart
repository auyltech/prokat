import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/chat/models/chat_message_model.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/chat/models/chat_sidebar_update.dart';
import 'package:prokat/features/chat/utils/chat_sidebar_update_utils.dart';

void main() {
  group('ChatSidebarUpdate.tryParse', () {
    test('parses lastMessage and unreadCount', () {
      final update = ChatSidebarUpdate.tryParse({
        'chatId': 'chat-1',
        'unreadCount': 2,
        'lastMessage': {
          'id': 'msg-2',
          'senderId': 'user-b',
          'content': 'hello',
          'createdAt': '2026-01-01T12:00:00.000Z',
        },
      });

      expect(update, isNotNull);
      expect(update!.chatId, 'chat-1');
      expect(update.unreadCount, 2);
      expect(update.lastMessage?.id, 'msg-2');
      expect(update.lastMessage?.chatId, 'chat-1');
      expect(update.lastMessage?.content, 'hello');
    });

    test('rejects payloads without chatId or update fields', () {
      expect(ChatSidebarUpdate.tryParse({'unreadCount': 1}), isNull);
      expect(ChatSidebarUpdate.tryParse({'chatId': 'chat-1'}), isNull);
      expect(ChatSidebarUpdate.tryParse('oops'), isNull);
    });
  });

  group('applyChatSidebarUpdateToItems', () {
    test('replaces preview, bumps unread, and reorders the list', () {
      final items = [
        ChatModel(
          id: 'older',
          lastMessage: _message(
            id: 'old',
            chatId: 'older',
            createdAt: DateTime.utc(2026, 1, 1, 10),
          ),
        ),
        ChatModel(
          id: 'chat-1',
          newMessagesCount: 1,
          lastMessage: _message(
            id: 'msg-1',
            createdAt: DateTime.utc(2026, 1, 1, 11),
          ),
        ),
      ];

      final result = applyChatSidebarUpdateToItems(
        items: items,
        currentUserId: 'user-me',
        update: ChatSidebarUpdate(
          chatId: 'chat-1',
          lastMessage: _message(
            id: 'msg-2',
            senderId: 'user-b',
            content: 'later',
            createdAt: DateTime.utc(2026, 1, 1, 12),
          ),
        ),
      );

      expect(result.status, ChatSidebarApplyStatus.applied);
      expect(result.items.first.id, 'chat-1');
      expect(result.items.first.lastMessage?.content, 'later');
      expect(result.items.first.newMessagesCount, 2);
    });

    test('does not increment unread for own messages or an open thread', () {
      final chat = ChatModel(id: 'chat-1', newMessagesCount: 0);
      final incoming = _message(
        id: 'msg-2',
        senderId: 'user-me',
        createdAt: DateTime.utc(2026, 1, 1, 12),
      );

      final own = applyChatSidebarUpdateToItems(
        items: [chat],
        currentUserId: 'user-me',
        update: ChatSidebarUpdate(chatId: 'chat-1', lastMessage: incoming),
      );
      expect(own.items.single.newMessagesCount, 0);

      final open = applyChatSidebarUpdateToItems(
        items: [chat],
        currentUserId: 'user-me',
        isThreadOpen: true,
        update: ChatSidebarUpdate(
          chatId: 'chat-1',
          lastMessage: incoming.copyWith(senderId: 'user-b'),
        ),
      );
      expect(open.items.single.newMessagesCount, 0);
      expect(open.items.single.lastMessage?.id, 'msg-2');
    });

    test(
      'keeps an existing newer preview and applies explicit unreadCount',
      () {
        final chat = ChatModel(
          id: 'chat-1',
          newMessagesCount: 4,
          lastMessage: _message(
            id: 'msg-new',
            content: 'new',
            createdAt: DateTime.utc(2026, 1, 1, 12),
          ),
        );

        final result = applyChatSidebarUpdateToItems(
          items: [chat],
          update: ChatSidebarUpdate(
            chatId: 'chat-1',
            unreadCount: 0,
            lastMessage: _message(
              id: 'msg-old',
              content: 'old',
              createdAt: DateTime.utc(2026, 1, 1, 11),
            ),
          ),
        );

        expect(result.items.single.lastMessage?.content, 'new');
        expect(result.items.single.newMessagesCount, 0);
      },
    );

    test('returns notFound when the chat is not cached', () {
      final result = applyChatSidebarUpdateToItems(
        items: [const ChatModel(id: 'other')],
        update: const ChatSidebarUpdate(chatId: 'chat-1', unreadCount: 1),
      );

      expect(result.status, ChatSidebarApplyStatus.notFound);
      expect(result.items.single.id, 'other');
    });
  });
}

ChatMessageModel _message({
  required String id,
  String chatId = 'chat-1',
  String senderId = 'user-b',
  String content = 'hello',
  DateTime? createdAt,
}) {
  return ChatMessageModel(
    id: id,
    chatId: chatId,
    senderId: senderId,
    content: content,
    createdAt: createdAt,
  );
}
