import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/providers/socket_provider.dart';
import 'package:prokat/features/chat/service/chat_socket_service.dart';

// final chatServiceProvider = Provider<ChatService>((ref) {
//   final apiClient = ref.watch(apiClientProvider);
//   return ChatService(apiClient);
// });

// final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
//   final service = ref.read(chatServiceProvider);
//   final socketService = ref.read(chatSocketServiceProvider);

//   // Ensure auth state is initialized early so we always have `currentUserId`
//   // available for message alignment + optimistic message sender id.
//   ref.watch(authProvider);

//   return ChatNotifier(ref, service, socketService);
// });
