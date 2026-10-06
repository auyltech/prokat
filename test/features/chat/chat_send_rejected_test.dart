import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/providers/socket_provider.dart';
import 'package:prokat/features/chat/service/chat_send_rejected.dart';
import 'package:prokat/features/chat/service/chat_socket_service.dart';

import '../../support/fake_app_socket_service.dart';

void main() {
  late ProviderContainer container;
  late FakeAppSocketService socket;
  late ChatSocketService chat;

  setUp(() {
    container = ProviderContainer(
      overrides: [appSocketProvider.overrideWith(FakeAppSocketService.new)],
    );
    socket = container.read(appSocketProvider) as FakeAppSocketService;
    chat = ChatSocketService(socket);
  });

  tearDown(() {
    chat.dispose();
    container.dispose();
  });

  test('USER_BLOCKED send ack throws ChatSendRejected with the code', () async {
    await chat.joinChat('chat-1');
    socket.ackResult = {
      'success': false,
      'message': 'Interaction with this user is unavailable',
      'code': 'USER_BLOCKED',
    };

    await expectLater(
      chat.sendMessage(chatId: 'chat-1', message: 'hi', type: 'TEXT'),
      throwsA(
        isA<ChatSendRejected>().having(
          (error) => error.code,
          'code',
          'USER_BLOCKED',
        ),
      ),
    );
  });

  test('a rejected ack without a code stays a plain exception', () async {
    await chat.joinChat('chat-1');
    socket.ackResult = {'success': false, 'message': 'Chat is closed'};

    await expectLater(
      chat.sendMessage(chatId: 'chat-1', message: 'hi', type: 'TEXT'),
      throwsA(allOf(isA<Exception>(), isNot(isA<ChatSendRejected>()))),
    );
  });
}
