import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/auth/providers/authenticated_session_scope.dart';

/// Tender ids the owner has already had on screen.
///
/// Drives the first-appearance animation only. The tab counter is deliberately
/// independent: a card the owner looked at but did not reject keeps counting.
/// Session-scoped, so the highlight can replay after an app restart.
class SeenRequestIdsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    ref.watch(authenticatedSessionScopeKeyProvider);
    return const <String>{};
  }

  bool isSeen(String requestId) => state.contains(requestId);

  void markSeen(String requestId) {
    if (requestId.isEmpty || state.contains(requestId)) return;
    state = {...state, requestId};
  }
}

final seenRequestIdsProvider =
    NotifierProvider<SeenRequestIdsNotifier, Set<String>>(
      SeenRequestIdsNotifier.new,
    );
