import 'dart:async';

import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/features/chat/state/chat_message_model.dart';
import 'package:prokat/features/auth/services/auth_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class ChatSocketService {
  static const String joinChatEvent = 'chat:join';
  static const String leaveChatEvent = 'chat:leave';
  static const String sendMessageEvent = 'chat:message:send';
  static const String newMessageEvent = 'chat:message:new';

  final ApiClient apiClient;
  final AuthSecureStorage secureStorage;

  io.Socket? _socket;
  String? _joinedChatId;

  ChatSocketService(this.apiClient, this.secureStorage);

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect({String? token}) async {
    if (isConnected) {
      return;
    }

    final resolvedToken = (token ?? '').trim().isNotEmpty
        ? token!.trim()
        : (await secureStorage.readSession())?.sessionToken ?? '';

    _socket?.dispose();
    _socket = io.io(
      apiClient.dio.options.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setExtraHeaders({
            if (resolvedToken.isNotEmpty)
              'Authorization': 'Bearer $resolvedToken',
          })
          .build(),
    );

    final completer = Completer<void>();
    _socket?.onConnect((_) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });
    _socket?.onConnectError((error) {
      if (!completer.isCompleted) {
        completer.completeError(Exception(error.toString()));
      }
    });

    _socket?.connect();
    await completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Socket connection timed out'),
    );
  }

  void onNewMessage(void Function(ChatMessageModel message) handler) {
    _socket?.off(newMessageEvent);
    _socket?.on(newMessageEvent, (payload) {
      if (payload is Map<String, dynamic>) {
        handler(ChatMessageModel.fromJson(payload));
        return;
      }

      if (payload is Map) {
        handler(ChatMessageModel.fromJson(Map<String, dynamic>.from(payload)));
      }
    });
  }

  Future<void> joinChat(String chatId) async {
    if (_joinedChatId == chatId) {
      return;
    }

    if ((_joinedChatId ?? '').isNotEmpty) {
      leaveChat(_joinedChatId!);
    }

    _socket?.emit(joinChatEvent, {'chatId': chatId});
    _joinedChatId = chatId;
  }

  void leaveChat(String chatId) {
    _socket?.emit(leaveChatEvent, {'chatId': chatId});
    if (_joinedChatId == chatId) {
      _joinedChatId = null;
    }
  }

  void sendMessage({
    required String chatId,
    required String message,
    required String type,
    String? clientTempId,
  }) {
    _socket?.emit(sendMessageEvent, {
      'chatId': chatId,
      'type': type,
      'content': message,
      if ((clientTempId ?? '').isNotEmpty) 'clientTempId': clientTempId,
    });
  }

  void disconnect() {
    if ((_joinedChatId ?? '').isNotEmpty) {
      leaveChat(_joinedChatId!);
    }

    _socket?.off(newMessageEvent);
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
