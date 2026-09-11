import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks the currently open chat screen id for live owner-status patches.
final openChatIdProvider = NotifierProvider<OpenChatIdNotifier, String?>(
  OpenChatIdNotifier.new,
);

class OpenChatIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void register(String chatId) {
    final id = chatId.trim();
    if (id.isEmpty || state == id) return;
    state = id;
  }

  void unregister(String chatId) {
    final id = chatId.trim();
    if (id.isEmpty) return;
    if (state == id) {
      state = null;
    }
  }
}

/// Watch from an open chat screen so mount registers and dispose unregisters.
final openChatRegistrationProvider = Provider.autoDispose.family<void, String>((
  ref,
  chatId,
) {
  ref.read(openChatIdProvider.notifier).register(chatId);
  ref.onDispose(() {
    ref.read(openChatIdProvider.notifier).unregister(chatId);
  });
});
