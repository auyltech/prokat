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

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}

