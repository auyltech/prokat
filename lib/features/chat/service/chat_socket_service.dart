import 'dart:async';

import 'package:prokat/features/chat/models/chat_message_model.dart';
import 'package:prokat/core/services/app_socket_service.dart';

class ChatSocketService {
  static const String joinChatEvent = 'chat:join';
  static const String leaveChatEvent = 'chat:leave';
  static const String sendMessageEvent = 'chat:message:send';
  static const String newMessageEvent = 'chat:message:new';

  final AppSocketService appSocket;

  String? _joinedChatId;
  int? _joinedConnectionGeneration;

  final List<String> _desiredChatIds = [];
  final List<_ChatMessageListenerRegistration> _messageListeners = [];

  Future<void> _roomOperation = Future<void>.value();

  final Object _connectListenerKey = Object();

  ChatSocketService(this.appSocket) {
    appSocket.addConnectListener(_connectListenerKey, _handleSocketConnected);
  }

  Future<void> connect() async {
    await appSocket.connect();
  }

  Future<void> sendMessage({
    required String chatId,
    required String message,
    required String type,
    String? clientTempId,
  }) async {
    final normalizedChatId = _normalizeChatId(chatId);

    await joinChat(normalizedChatId);

    appSocket.emit(sendMessageEvent, {
      'chatId': normalizedChatId,
      'type': type,
      'content': message,
      if ((clientTempId ?? '').isNotEmpty) 'clientTempId': clientTempId,
    });
  }

  void Function() onNewMessage(
    void Function(ChatMessageModel message) handler,
  ) {
    final token = Object();
    _messageListeners.add(
      _ChatMessageListenerRegistration(token: token, handler: handler),
    );
    _attachActiveMessageListener();

    return () {
      _messageListeners.removeWhere(
        (registration) => identical(registration.token, token),
      );
      _attachActiveMessageListener();
    };
  }

  void _attachActiveMessageListener() {
    if (_messageListeners.isEmpty) {
      appSocket.off(newMessageEvent);
      return;
    }

    final active = _messageListeners.last;
    appSocket.on(newMessageEvent, (payload) {
      if (payload is Map<String, dynamic>) {
        active.handler(ChatMessageModel.fromJson(payload));
        return;
      }

      if (payload is Map) {
        active.handler(
          ChatMessageModel.fromJson(Map<String, dynamic>.from(payload)),
        );
      }
    });
  }

  Future<void> joinChat(String chatId) async {
    final normalizedChatId = _normalizeChatId(chatId);
    _desiredChatIds
      ..remove(normalizedChatId)
      ..add(normalizedChatId);

    return _enqueueRoomOperation(() => _joinChat(normalizedChatId));
  }

  Future<void> _joinChat(String chatId) async {
    await appSocket.connect();

    if (_desiredChatId != chatId) {
      return;
    }

    if (_joinedChatId == chatId &&
        _joinedConnectionGeneration == appSocket.connectionGeneration) {
      return;
    }

    final joinedChatId = _joinedChatId;
    if ((joinedChatId ?? '').isNotEmpty && joinedChatId != chatId) {
      await _leaveChat(joinedChatId!);
    }

    appSocket.emit(joinChatEvent, {'chatId': chatId});

    _joinedChatId = chatId;
    _joinedConnectionGeneration = appSocket.connectionGeneration;
  }

  Future<void> leaveChat(String chatId) async {
    final normalizedChatId = chatId.trim();

    if (normalizedChatId.isEmpty) return;

    _desiredChatIds.remove(normalizedChatId);

    return _enqueueRoomOperation(() async {
      await _leaveChat(normalizedChatId);

      final desiredChatId = _desiredChatId;
      if (desiredChatId != null) {
        await _joinChat(desiredChatId);
      }
    });
  }

  Future<void> _leaveChat(String chatId) async {
    if (_joinedChatId != chatId) {
      return;
    }

    if (!appSocket.isConnected) {
      _joinedChatId = null;
      _joinedConnectionGeneration = null;
      return;
    }

    try {
      final response = await appSocket.emitWithAck(leaveChatEvent, {
        'chatId': chatId,
      });

      _requireSuccessfulAck(response, 'Failed to leave chat');
    } finally {
      if (_joinedChatId == chatId) {
        _joinedChatId = null;
        _joinedConnectionGeneration = null;
      }
    }
  }

  // Leave current chat room + remove chat listeners.
  Future<void> disposeChatSession() async {
    final chatId = _joinedChatId;

    if ((chatId ?? '').trim().isNotEmpty) {
      try {
        await leaveChat(chatId!);
      } finally {}
    }

    _joinedChatId = null;
    _desiredChatIds.clear();
    _joinedConnectionGeneration = null;
    appSocket.off(newMessageEvent);
    _messageListeners.clear();
  }

  void _handleSocketConnected() {
    final chatId = _desiredChatId;
    if ((chatId ?? '').isEmpty) {
      return;
    }

    unawaited(
      _enqueueRoomOperation(() => _joinChat(chatId!)).catchError((_) {}),
    );
  }

  String? get _desiredChatId {
    return _desiredChatIds.isEmpty ? null : _desiredChatIds.last;
  }

  Future<void> _enqueueRoomOperation(Future<void> Function() operation) {
    final previous = _roomOperation;
    final next = () async {
      try {
        await previous;
      } catch (_) {}

      await operation();
    }();

    _roomOperation = next;
    return next;
  }

  String _normalizeChatId(String chatId) {
    final normalized = chatId.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(chatId, 'chatId', 'Chat ID cannot be empty');
    }

    return normalized;
  }

  void _requireSuccessfulAck(dynamic response, String fallbackMessage) {
    if (response == true) {
      return;
    }

    if (response is Map) {
      if (response['success'] == false || response['error'] != null) {
        throw Exception(
          response['message'] ?? response['error'] ?? fallbackMessage,
        );
      }

      return;
    }

    if (response == null || response == false) {
      throw Exception(fallbackMessage);
    }
  }

  void dispose() {
    _desiredChatIds.clear();
    _messageListeners.clear();
    appSocket.removeConnectListener(_connectListenerKey);
    appSocket.off(newMessageEvent);
  }
}

class _ChatMessageListenerRegistration {
  final Object token;
  final void Function(ChatMessageModel message) handler;

  const _ChatMessageListenerRegistration({
    required this.token,
    required this.handler,
  });
}
