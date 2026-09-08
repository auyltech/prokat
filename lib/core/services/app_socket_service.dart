import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/core/config/env.dart';
import 'package:prokat/core/errors/socket_connect_exception.dart';
import 'package:prokat/core/services/crash_reporting_service.dart';
import 'package:prokat/core/utils/logger.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class AppSocketService {
  final ApiClient apiClient;
  final Ref ref;

  io.Socket? _socket;
  Future<void>? _connecting;
  int _connectionGeneration = 0;

  final Map<String, void Function(dynamic payload)> _eventHandlers = {};
  final Map<Object, void Function()> _connectListeners = {};

  AppSocketService(this.apiClient, this.ref);

  bool get isConnected => _socket?.connected ?? false;
  int get connectionGeneration => _connectionGeneration;

  Future<void> connect() async {
    if (isConnected) {
      return;
    }

    final connecting = _connecting;
    if (connecting != null) {
      return connecting;
    }

    final connection = _connect();
    _connecting = connection;

    try {
      await connection;
    } finally {
      if (identical(_connecting, connection)) {
        _connecting = null;
      }
    }
  }

  Future<void> _connect() async {
    final session = ref.read(authProvider).session;
    final sessionToken = session?.sessionToken?.trim() ?? '';
    final userId = session?.user?.id?.trim();

    if (sessionToken.isEmpty) {
      throw StateError(
        'Cannot connect socket without an authenticated session',
      );
    }

    _socket?.dispose();

    final socket = io.io(
      Env.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableForceNew()
          .setAuth({'token': sessionToken})
          .setExtraHeaders({'Authorization': 'Bearer $sessionToken'})
          .build(),
    );

    _socket = socket;

    for (final entry in _eventHandlers.entries) {
      socket.on(entry.key, entry.value);
    }

    final completer = Completer<void>();
    var reportedConnectError = false;

    void failHandshake(Object error, [StackTrace? stackTrace]) {
      final exception = error is SocketConnectException
          ? error
          : SocketConnectException(
              message: SocketConnectException.messageFrom(error),
              cause: error,
              hasToken: sessionToken.isNotEmpty,
              tokenLength: sessionToken.length,
              sessionExpiredOnClient: session?.isExpired ?? false,
              socketUrl: Env.socketUrl,
              userId: userId,
            );

      if (!reportedConnectError) {
        reportedConnectError = true;
        unawaited(
          CrashReportingService.recordError(
            exception,
            stackTrace ?? StackTrace.current,
            reason: 'socket_connect',
            keys: {
              ...exception.crashlyticsKeys,
              'app_env': Env.environment.name,
            },
            userId: userId,
            fatal: true,
          ),
        );
      }

      Logger.log('Socket connect error: ${exception.message}');

      if (!completer.isCompleted) {
        completer.completeError(exception, stackTrace);
      }
    }

    socket.onConnect((_) {
      if (!identical(_socket, socket)) {
        return;
      }

      _connectionGeneration++;

      if (!completer.isCompleted) {
        completer.complete();
      }

      Logger.log(
        'Socket connected user=${userId ?? 'none'} url=${Env.socketUrl}',
      );

      scheduleMicrotask(_notifyConnectListeners);
    });

    socket.onConnectError((error) {
      failHandshake(error is Object ? error : error.toString());
    });

    socket.connect();

    try {
      await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Socket connection timed out');
        },
      );
    } catch (error, stackTrace) {
      if (identical(_socket, socket)) {
        try {
          socket.dispose();
        } catch (_) {}
        _socket = null;
      }

      if (error is SocketConnectException) {
        Error.throwWithStackTrace(error, stackTrace);
      }

      failHandshake(error, stackTrace);
      Error.throwWithStackTrace(
        SocketConnectException(
          message: SocketConnectException.messageFrom(error),
          cause: error,
          hasToken: sessionToken.isNotEmpty,
          tokenLength: sessionToken.length,
          sessionExpiredOnClient: session?.isExpired ?? false,
          socketUrl: Env.socketUrl,
          userId: userId,
        ),
        stackTrace,
      );
    }
  }

  void on(String event, void Function(dynamic payload) handler) {
    _eventHandlers[event] = handler;
    _socket?.off(event);
    _socket?.on(event, handler);
  }

  void off(String event) {
    _eventHandlers.remove(event);
    _socket?.off(event);
  }

  void addConnectListener(Object key, void Function() listener) {
    _connectListeners[key] = listener;
  }

  void removeConnectListener(Object key) {
    _connectListeners.remove(key);
  }

  void _notifyConnectListeners() {
    for (final listener in _connectListeners.values.toList()) {
      try {
        listener();
      } catch (_) {}
    }
  }

  void emit(String event, dynamic data) {
    final socket = _socket;

    if (socket == null || !socket.connected) {
      throw StateError('Socket is not connected');
    }

    socket.emit(event, data);
  }

  Future<dynamic> emitWithAck(
    String event,
    dynamic data, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final socket = _socket;

    if (socket == null || !socket.connected) {
      throw Exception('Socket is not connected');
    }

    final completer = Completer<dynamic>();

    socket.emitWithAck(
      event,
      data,
      ack: (response) {
        if (!completer.isCompleted) {
          completer.complete(response);
        }
      },
    );

    return completer.future.timeout(
      timeout,
      onTimeout: () {
        throw TimeoutException('$event timed out');
      },
    );
  }

  // Full Socket ShutDown, called when
  // user signs out
  // app goes to background, if you choose to fully disconnect
  // auth session is cleared
  // socket token is invalid
  void disconnectSocket() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
