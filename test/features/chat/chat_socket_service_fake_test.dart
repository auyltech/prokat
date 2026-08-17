import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/providers/socket_provider.dart';
import 'package:prokat/features/chat/service/chat_socket_service.dart';

import '../../support/fake_app_socket_service.dart';

void main() {
  test('join emits once and leave acks once on the fake socket', () async {
    final env = _ChatSocketHarness();
    addTearDown(env.dispose);

    await env.chat.joinChat('chat-1');
    await _settle();

    // connect() notifies listeners, which enqueue a second _joinChat.
    // That second call is a no-op join but still invokes connect().
    expect(env.socket.connectCalls, 2);
    expect(env.socket.joinEmits, 1);
    expect(env.socket.leaveEmits, 0);
    expect(env.socket.emitted.single.$2, {'chatId': 'chat-1'});

    await env.chat.leaveChat('chat-1');

    expect(env.socket.connectCalls, 2);
    expect(env.socket.joinEmits, 1);
    expect(env.socket.leaveEmits, 1);
  });

  test('reconnect rejoins the desired chat once', () async {
    final env = _ChatSocketHarness();
    addTearDown(env.dispose);

    await env.chat.joinChat('chat-1');
    await _settle();
    env.socket.simulateReconnect();
    await _settle();

    expect(env.socket.joinEmits, 2);
    expect(env.socket.connectionGeneration, 2);
  });

  test(
    'every registered message listener receives the inbound event',
    () async {
      final env = _ChatSocketHarness();
      addTearDown(env.dispose);
      final first = <String>[];
      final second = <String>[];

      await env.chat.joinChat('chat-1');
      final removeFirst = env.chat.onNewMessage(
        (message) => first.add(message.id),
      );
      final removeSecond = env.chat.onNewMessage(
        (message) => second.add(message.id),
      );
      env.socket.emitIncoming('chat:message:new', _messageJson('message-1'));

      expect(first, ['message-1']);
      expect(second, ['message-1']);
      expect(
        env.socket.onEvents.where((event) => event == 'chat:message:new'),
        hasLength(1),
      );

      removeFirst();
      env.socket.emitIncoming('chat:message:new', _messageJson('message-2'));

      expect(first, ['message-1']);
      expect(second, ['message-1', 'message-2']);
      expect(env.socket.offEvents, isEmpty);

      removeSecond();
      expect(env.socket.offEvents, ['chat:message:new']);
    },
  );

  test('duplicate inbound messages are delivered as emitted', () async {
    final env = _ChatSocketHarness();
    addTearDown(env.dispose);
    final ids = <String>[];

    await env.chat.joinChat('chat-1');
    env.chat.onNewMessage((message) => ids.add(message.id));
    env.socket.emitIncoming('chat:message:new', _messageJson('message-1'));
    env.socket.emitIncoming('chat:message:new', _messageJson('message-1'));

    expect(ids, ['message-1', 'message-1']);
  });

  test('connect can be delayed until the test releases it', () async {
    final env = _ChatSocketHarness();
    addTearDown(env.dispose);
    env.socket.connectGate = Completer<void>();

    final joining = env.chat.joinChat('chat-1');
    await _settle();
    expect(env.socket.joinEmits, 0);

    env.socket.connectGate!.complete();
    await joining;
    await _settle();

    expect(env.socket.joinEmits, 1);
  });
}

class _ChatSocketHarness {
  _ChatSocketHarness() {
    late FakeAppSocketService socket;
    container = ProviderContainer(
      overrides: [
        appSocketProvider.overrideWith((ref) {
          socket = FakeAppSocketService(ref);
          return socket;
        }),
      ],
    );
    this.socket = container.read(appSocketProvider) as FakeAppSocketService;
    chat = ChatSocketService(this.socket);
  }

  late final ProviderContainer container;
  late final FakeAppSocketService socket;
  late final ChatSocketService chat;

  void dispose() {
    chat.dispose();
    container.dispose();
  }
}

Map<String, dynamic> _messageJson(String id) => {
  'id': id,
  'chatId': 'chat-1',
  'senderId': 'user-a',
  'content': 'hello',
  'type': 'TEXT',
  'createdAt': '2026-01-01T00:00:00.000Z',
};

Future<void> _settle() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}
