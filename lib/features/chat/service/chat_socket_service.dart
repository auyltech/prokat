import 'dart:async';

import 'package:prokat/features/chat/models/chat_message_model.dart';
import 'package:prokat/features/chat/models/chat_sidebar_update.dart';
import 'package:prokat/core/services/app_socket_service.dart';

class ChatSocketService {
  static const String joinChatEvent = 'chat:join';
  static const String leaveChatEvent = 'chat:leave';
  static const String sendMessageEvent = 'chat:message:send';
  static const String newMessageEvent = 'chat:message:new';
  static const String sidebarUpdateEvent = 'chat:sidebar:update';

  final AppSocketService appSocket;

  String? _joinedChatId;
  int? _joinedConnectionGeneration;
  String? _inFlightJoinChatId;

  final List<String> _desiredChatIds = [];
  final List<_ChatMessageListenerRegistration> _messageListeners = [];
  final List<_ChatSidebarListenerRegistration> _sidebarListeners = [];
  bool _newMessageSocketAttached = false;
  bool _sidebarSocketAttached = false;

  String? get activeChatId => _desiredChatId;

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

  void Function() onSidebarUpdate(
    void Function(ChatSidebarUpdate update) handler,
  ) {
    final token = Object();
    _sidebarListeners.add(
      _ChatSidebarListenerRegistration(token: token, handler: handler),
    );
    _attachActiveSidebarListener();

    return () {
      _sidebarListeners.removeWhere(
        (registration) => identical(registration.token, token),
      );
      _attachActiveSidebarListener();
    };
  }

  void _attachActiveMessageListener() {
    if (_messageListeners.isEmpty) {
      if (_newMessageSocketAttached) {
        appSocket.off(newMessageEvent);
        _newMessageSocketAttached = false;
      }
      return;
    }

    if (_newMessageSocketAttached) return;

    _newMessageSocketAttached = true;
    appSocket.on(newMessageEvent, (payload) {
      final message = _parseIncomingMessage(payload);
      if (message == null) return;

      for (final registration in List<_ChatMessageListenerRegistration>.from(
        _messageListeners,
      )) {
        registration.handler(message);
      }
    });
  }

  void _attachActiveSidebarListener() {
    if (_sidebarListeners.isEmpty) {
      if (_sidebarSocketAttached) {
        appSocket.off(sidebarUpdateEvent);
        _sidebarSocketAttached = false;
      }
      return;
    }

    if (_sidebarSocketAttached) return;

    _sidebarSocketAttached = true;
    appSocket.on(sidebarUpdateEvent, (payload) {
      final update = ChatSidebarUpdate.tryParse(payload);
      if (update == null) return;

      for (final registration in List<_ChatSidebarListenerRegistration>.from(
        _sidebarListeners,
      )) {
        registration.handler(update);
      }
    });
  }

  ChatMessageModel? _parseIncomingMessage(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      return ChatMessageModel.fromJson(payload);
    }

    if (payload is Map) {
      return ChatMessageModel.fromJson(Map<String, dynamic>.from(payload));
    }

    return null;
  }

  Future<void> joinChat(String chatId) async {
    final normalizedChatId = _normalizeChatId(chatId);
    _desiredChatIds
      ..remove(normalizedChatId)
      ..add(normalizedChatId);

    return _enqueueRoomOperation(() => _joinChat(normalizedChatId));
  }

  Future<void> _joinChat(String chatId) async {
    _inFlightJoinChatId = chatId;
    try {
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
    } finally {
      if (_inFlightJoinChatId == chatId) {
        _inFlightJoinChatId = null;
      }
    }
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
    _inFlightJoinChatId = null;
    _messageListeners.clear();
    _newMessageSocketAttached = false;
    appSocket.off(newMessageEvent);
  }

  void _handleSocketConnected() {
    final chatId = _desiredChatId;
    if ((chatId ?? '').isEmpty) {
      return;
    }

    if (_joinedChatId == chatId &&
        _joinedConnectionGeneration == appSocket.connectionGeneration) {
      return;
    }

    if (_inFlightJoinChatId == chatId) {
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
    _inFlightJoinChatId = null;
    _messageListeners.clear();
    _sidebarListeners.clear();
    _newMessageSocketAttached = false;
    _sidebarSocketAttached = false;
    appSocket.removeConnectListener(_connectListenerKey);
    appSocket.off(newMessageEvent);
    appSocket.off(sidebarUpdateEvent);
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

class _ChatSidebarListenerRegistration {
  final Object token;
  final void Function(ChatSidebarUpdate update) handler;

  const _ChatSidebarListenerRegistration({
    required this.token,
    required this.handler,
  });
}
