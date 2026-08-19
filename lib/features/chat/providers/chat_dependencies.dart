import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/api/api_provider.dart';
import 'package:prokat/core/providers/socket_provider.dart';
import 'package:prokat/features/chat/service/chat_service.dart';
import 'package:prokat/features/chat/service/chat_socket_service.dart';

final chatServiceProvider = Provider<ChatService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ChatService(apiClient);
});

final chatSocketServiceProvider = Provider<ChatSocketService>((ref) {
  final appSocket = ref.watch(appSocketProvider);
  final service = ChatSocketService(appSocket);
  ref.onDispose(service.dispose);
  return service;
});
