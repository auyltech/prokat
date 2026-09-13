import 'dart:async';

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
///
/// [register] is deferred: Riverpod forbids modifying another provider while
/// this one is initializing (sync write from create would assert).
final openChatRegistrationProvider = Provider.autoDispose.family<void, String>((
  ref,
  chatId,
) {
  var disposed = false;
  ref.onDispose(() {
    disposed = true;
    ref.read(openChatIdProvider.notifier).unregister(chatId);
  });
  unawaited(
    Future.microtask(() {
      if (disposed) return;
      ref.read(openChatIdProvider.notifier).register(chatId);
    }),
  );
});
