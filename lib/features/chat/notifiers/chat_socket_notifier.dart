import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/chat/providers/chat_providers.dart';
import 'package:prokat/features/chat/models/chat_message_model.dart';
import 'package:prokat/features/chat/service/chat_socket_service.dart';

class ChatSocketNotifier {
  final Ref ref;
  final ChatSocketService socket;

  StreamSubscription? _subscription;

  bool _initialized = false;

  ChatSocketNotifier(this.ref, this.socket);

  Future<void> connect() async {
    await socket.connect();

    if (_initialized) {
      return;
    }

    _initialized = true;

    _listen();
  }

  Future<void> disconnect() async {
    await socket.disposeChatSession();

    await _subscription?.cancel();
    _subscription = null;

    _initialized = false;
  }

  Future<void> joinChat(String chatId) async {
    await socket.joinChat(chatId);
  }

  Future<void> leaveChat(String chatId) async {
    await socket.leaveChat(chatId);
  }

  void _listen() {
    socket.onNewMessage(_handleIncomingMessage);
  }

  void _handleIncomingMessage(ChatMessageModel message) {
    final notifier = ref.read(chatMessagesProvider(message.chatId).notifier);

    final replaced = notifier.replacePending(message);

    if (!replaced) {
      notifier.mergeIncoming(message);
    }

    _refreshChat(message.chatId);
  }

  void _refreshChat(String chatId) {
    ref.read(chatProvider(chatId).notifier).refresh();

    ref.read(clientChatsProvider.notifier).refreshIfStale();

    ref.read(ownerChatsProvider.notifier).refreshIfStale();
  }

  Future<void> dispose() async {
    await disconnect();
  }
}
