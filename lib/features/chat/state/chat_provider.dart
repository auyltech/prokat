import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/api/api_provider.dart';
import 'package:prokat/core/providers/socket_provider.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/chat/state/chat_notifier.dart';
import 'package:prokat/features/chat/state/chat_service.dart';
import 'package:prokat/features/chat/state/chat_socket_service.dart';
import 'package:prokat/features/chat/state/chat_state.dart';

final chatServiceProvider = Provider<ChatService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ChatService(apiClient);
});

final chatSocketServiceProvider = Provider<ChatSocketService>((ref) {
  final appSocket = ref.watch(appSocketProvider);
  return ChatSocketService(appSocket);
});

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final service = ref.read(chatServiceProvider);
  final socketService = ref.read(chatSocketServiceProvider);

  // Ensure auth state is initialized early so we always have `currentUserId`
  // available for message alignment + optimistic message sender id.
  ref.watch(authProvider);

  return ChatNotifier(ref, service, socketService);
});
