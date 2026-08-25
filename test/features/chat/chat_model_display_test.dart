import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/auth/models/user_model.dart';
import 'package:prokat/features/chat/models/chat_model.dart';

void main() {
  const client = UserModel(
    id: 'client-1',
    firstName: 'Алия',
    lastName: 'Нурланова',
    imageUrl: 'https://example.com/client.jpg',
  );
  const owner = UserModel(
    id: 'owner-1',
    firstName: 'Ерлан',
    lastName: 'Садыков',
    imageUrl: 'https://example.com/owner.jpg',
  );

  const chat = ChatModel(
    id: 'chat-1',
    type: ChatType.direct,
    client: client,
    owner: owner,
  );

  group('ChatModel.displayTitle', () {
    test('shows the owner when the current user is the client', () {
      expect(
        chat.displayTitle(
          client.id!,
          ownerFallback: 'Owner',
          clientFallback: 'Client',
        ),
        'Ерлан Садыков',
      );
    });

    test('shows the client when the current user is the owner', () {
      expect(
        chat.displayTitle(
          owner.id!,
          ownerFallback: 'Owner',
          clientFallback: 'Client',
        ),
        'Алия Нурланова',
      );
    });

    test('uses fallback when counterpart has only a phone number', () {
      const chatWithoutName = ChatModel(
        id: 'chat-3',
        type: ChatType.direct,
        client: client,
        owner: UserModel(id: 'owner-1', phoneNumber: '+77052222222'),
      );

      expect(
        chatWithoutName.displayTitle(
          client.id!,
          ownerFallback: 'Owner',
          clientFallback: 'Client',
        ),
        'Owner',
      );
    });
  });

  group('ChatModel.displayImageUrl', () {
    test('shows the owner avatar when the current user is the client', () {
      expect(chat.displayImageUrl(currentUserId: client.id), owner.imageUrl);
    });

    test('shows the client avatar when the current user is the owner', () {
      expect(chat.displayImageUrl(currentUserId: owner.id), client.imageUrl);
    });

    test('does not fall back to the current user photo', () {
      const chatWithoutOwnerPhoto = ChatModel(
        id: 'chat-2',
        type: ChatType.direct,
        client: client,
        owner: UserModel(
          id: 'owner-1',
          firstName: 'Ерлан',
          lastName: 'Садыков',
        ),
      );

      expect(
        chatWithoutOwnerPhoto.displayImageUrl(currentUserId: client.id),
        isNull,
      );
    });
  });
}
