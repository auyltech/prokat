import 'dart:async';

import 'package:flutter/foundation.dart';
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
  Completer<void>? _handshakeCompleter;
  int _connectionGeneration = 0;
  bool _keepAlive = false;
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;

  final Map<String, void Function(dynamic payload)> _eventHandlers = {};
  final Map<Object, void Function()> _connectListeners = {};

  AppSocketService(this.apiClient, this.ref);

  bool get isConnected => _socket?.connected ?? false;

  /// Android `localhost` often resolves to IPv6 `::1` first. adb reverse
  /// forwards 127.0.0.1, and a local IPv6 listener can accept the socket
  /// without completing the handshake.
  static String _ipv4Loopback(String url) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return url;
    final uri = Uri.tryParse(url.trim());
    if (uri == null || uri.host != 'localhost') return url;
    return uri.replace(host: '127.0.0.1').toString();
  }

  int get connectionGeneration => _connectionGeneration;

  Future<void> connect() async {
    _keepAlive = true;
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

    // Native socket_io_client always opens a WebSocket, and it puts the
    // first transport name in the handshake URL. "polling" makes the server
    // wait for an XHR body that never comes, so the connect call times out.
    final socketUrl = _ipv4Loopback(Env.socketUrl);
    final socket = io.io(
      socketUrl,
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
    _handshakeCompleter = completer;
    var reportedConnectError = false;

    SocketConnectException wrapError(Object error) {
      if (error is SocketConnectException) return error;
      return SocketConnectException(
        message: SocketConnectException.messageFrom(error),
        cause: error,
        hasToken: sessionToken.isNotEmpty,
        tokenLength: sessionToken.length,
        sessionExpiredOnClient: session?.isExpired ?? false,
        socketUrl: socketUrl,
        userId: userId,
      );
    }

    void failHandshake(Object error, [StackTrace? stackTrace]) {
      final exception = wrapError(error);

      if (!reportedConnectError && exception.shouldReportToCrashlytics) {
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
            // App keeps running; do not mark as a process crash.
            fatal: false,
          ),
        );
      }

      if (exception.isExpectedDisconnect) {
        Logger.log(
          'Socket connect deferred: ${exception.message} url=$socketUrl',
        );
      } else {
        Logger.log('Socket connect error: ${exception.message} url=$socketUrl');
      }

      if (!completer.isCompleted) {
        completer.completeError(exception, stackTrace);
      }
    }

    socket.onDisconnect((_) {
      if (!identical(_socket, socket)) return;
      Logger.log('Socket disconnected');
      _scheduleReconnect();
    });

    socket.onConnect((_) {
      if (!identical(_socket, socket)) {
        return;
      }

      _reconnectAttempt = 0;
      _reconnectTimer?.cancel();
      _connectionGeneration++;

      if (!completer.isCompleted) {
        completer.complete();
      }

      Logger.log(
        'Socket connected user=${userId ?? 'none'} url=$socketUrl',
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

      final exception = wrapError(error);
      if (error is! SocketConnectException) {
        // Timeout / transport errors land here; onConnectError already
        // went through failHandshake and rethrows SocketConnectException.
        failHandshake(exception, stackTrace);
      } else if (exception.isExpectedDisconnect) {
        // disconnectSocket aborted the wait — log once, no Crashlytics.
        Logger.log('Socket connect deferred: ${exception.message}');
      }
      Error.throwWithStackTrace(exception, stackTrace);
    } finally {
      if (identical(_handshakeCompleter, completer)) {
        _handshakeCompleter = null;
      }
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
  void _scheduleReconnect() {
    if (!_keepAlive || isConnected) return;
    _reconnectTimer?.cancel();
    final step = _reconnectAttempt.clamp(0, 4);
    final delay = Duration(milliseconds: 400 * (1 << step));
    _reconnectTimer = Timer(delay, () {
      if (!_keepAlive || isConnected) return;
      _reconnectAttempt++;
      unawaited(
        connect()
            .then((_) {
              _reconnectAttempt = 0;
            })
            .catchError((Object _) {
              if (_keepAlive) _scheduleReconnect();
            }),
      );
    });
  }

  void disconnectSocket() {
    _keepAlive = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempt = 0;
    final handshake = _handshakeCompleter;
    if (handshake != null && !handshake.isCompleted) {
      handshake.completeError(
        SocketConnectException(
          message: 'Socket connection cancelled',
          hasToken: true,
          tokenLength: 0,
          sessionExpiredOnClient: false,
          socketUrl: Env.socketUrl,
        ),
      );
    }
    _handshakeCompleter = null;

    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
