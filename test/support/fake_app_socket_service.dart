import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/core/services/app_socket_service.dart';

class FakeAppSocketService extends AppSocketService {
  FakeAppSocketService(Ref ref) : super(_UnusedApiClient(), ref);

  bool _connected = false;
  int _generation = 0;
  Completer<void>? connectGate;
  dynamic ackResult = true;

  int connectCalls = 0;
  int disconnectCalls = 0;
  final List<String> onEvents = [];
  final List<String> offEvents = [];
  final List<(String event, dynamic data)> emitted = [];

  final Map<String, void Function(dynamic payload)> _handlers = {};
  final Map<Object, void Function()> _connectListeners = {};

  @override
  bool get isConnected => _connected;

  @override
  int get connectionGeneration => _generation;

  @override
  Future<void> connect() async {
    connectCalls++;
    if (_connected) return;

    final gate = connectGate;
    if (gate != null) await gate.future;

    _connected = true;
    _generation++;
    _notifyConnected();
  }

  @override
  void disconnectSocket() {
    disconnectCalls++;
    _connected = false;
  }

  @override
  void on(String event, void Function(dynamic payload) handler) {
    onEvents.add(event);
    _handlers[event] = handler;
  }

  @override
  void off(String event) {
    offEvents.add(event);
    _handlers.remove(event);
  }

  @override
  void addConnectListener(Object key, void Function() listener) {
    _connectListeners[key] = listener;
  }

  @override
  void removeConnectListener(Object key) {
    _connectListeners.remove(key);
  }

  @override
  void emit(String event, dynamic data) {
    if (!_connected) {
      throw StateError('Socket is not connected');
    }
    emitted.add((event, data));
  }

  @override
  Future<dynamic> emitWithAck(
    String event,
    dynamic data, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    if (!_connected) {
      throw Exception('Socket is not connected');
    }
    emitted.add((event, data));
    return ackResult;
  }

  void emitIncoming(String event, dynamic payload) {
    _handlers[event]?.call(payload);
  }

  void simulateReconnect() {
    if (!_connected) {
      _connected = true;
    }
    _generation++;
    _notifyConnected();
  }

  int get joinEmits => emitted.where((item) => item.$1 == 'chat:join').length;

  int get leaveEmits => emitted.where((item) => item.$1 == 'chat:leave').length;

  void _notifyConnected() {
    for (final listener in _connectListeners.values.toList()) {
      listener();
    }
  }
}

class _UnusedApiClient implements ApiClient {
  @override
  Dio dio = Dio();
}
