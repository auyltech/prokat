import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/chat/providers/chat_providers.dart';
import 'package:prokat/features/chat/providers/current_chat_provider.dart';

final postMutationCacheCoordinatorProvider =
    Provider<PostMutationCacheCoordinator>(PostMutationCacheCoordinator.new);

class PostMutationCacheCoordinator {
  PostMutationCacheCoordinator(this.ref);

  final Ref ref;

  Future<void> refreshAffectedChats(String? chatId) async {
    final refreshes = <Future<void>>[];
    final id = (chatId ?? '').trim();

    if (id.isNotEmpty) {
      final currentChat = currentChatProvider(id);
      final messages = chatMessagesProvider(id);
      if (ref.exists(currentChat)) {
        refreshes.add(ref.read(currentChat.notifier).refresh());
      }
      if (ref.exists(messages)) {
        refreshes.add(ref.read(messages.notifier).refresh());
      }
    }

    if (ref.exists(clientChatsProvider)) {
      refreshes.add(ref.read(clientChatsProvider.notifier).refresh());
    }
    if (ref.exists(ownerChatsProvider)) {
      refreshes.add(ref.read(ownerChatsProvider.notifier).refresh());
    }

    await Future.wait(refreshes);
  }
}
