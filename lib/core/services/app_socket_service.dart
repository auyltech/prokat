import 'dart:async';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/features/auth/providers/auth_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class AppSocketService {
  final ApiClient apiClient;
  final AuthSecureStorage secureStorage;

  io.Socket? _socket;

  AppSocketService(this.apiClient, this.secureStorage);

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect({String? token}) async {
    if (isConnected) {
      return;
    }

    final resolvedToken = (token ?? '').trim().isNotEmpty
        ? token!.trim()
        : (await secureStorage.readSession())?.sessionToken ?? '';

    if (resolvedToken.trim().isEmpty) {
      throw Exception('Socket auth token is missing');
    }

    _socket?.dispose();

    _socket = io.io(
      apiClient.dio.options.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': resolvedToken})
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

  void on(String event, void Function(dynamic payload) handler) {
    _socket?.off(event);
    _socket?.on(event, handler);
  }

  void off(String event) {
    _socket?.off(event);
  }

  void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }

  Future<dynamic> emitWithAck(
    String event,
    dynamic data, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final socket = _socket;

    if (socket == null) {
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
