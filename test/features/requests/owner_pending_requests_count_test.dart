import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/auth/providers/authenticated_session_scope.dart';
import 'package:prokat/features/layout/navigation_counts_provider.dart';
import 'package:prokat/features/requests/providers/owner_pending_requests_count_provider.dart';
import 'package:prokat/features/chat/providers/chat_unread_providers.dart';

void main() {
  ProviderContainer container(Future<NavigationCounts> Function() load) {
    final result = ProviderContainer(
      overrides: [
        authenticatedSessionScopeKeyProvider.overrideWithValue(
          const AuthenticatedSessionScopeKey.forUser('owner'),
        ),
        navigationCountsLoaderProvider.overrideWithValue(load),
      ],
    );
    addTearDown(result.dispose);
    return result;
  }

  test('badges use server totals beyond list page sizes', () async {
    final c = container(
      () async => const NavigationCounts(
        pendingRequests: 47,
        clientUnread: 65,
        ownerUnread: 108,
      ),
    );
    c.read(navigationCountsProvider);
    await Future<void>.delayed(Duration.zero);
    expect(c.read(ownerPendingRequestsCountProvider), 47);
    expect(c.read(clientChatUnreadCountProvider), 65);
    expect(c.read(ownerChatUnreadCountProvider), 108);
  });

  test('failed refresh preserves the last verified totals', () async {
    var fail = false;
    final c = container(() async {
      if (fail) throw Exception('offline');
      return const NavigationCounts(pendingRequests: 47);
    });
    c.read(navigationCountsProvider);
    await Future<void>.delayed(Duration.zero);
    fail = true;
    await c.read(navigationCountsProvider.notifier).refresh();
    expect(c.read(navigationCountsProvider).hasError, isTrue);
    expect(c.read(ownerPendingRequestsCountProvider), 47);
  });

  test('events during an in-flight load cause one follow-up fetch', () async {
    final first = Completer<NavigationCounts>();
    var calls = 0;
    final c = container(() {
      calls++;
      return calls == 1
          ? first.future
          : Future.value(const NavigationCounts(pendingRequests: 2));
    });
    c.read(navigationCountsProvider);
    await Future<void>.delayed(Duration.zero);
    await c.read(navigationCountsProvider.notifier).refresh();
    await c.read(navigationCountsProvider.notifier).refresh();
    first.complete(const NavigationCounts(pendingRequests: 3));
    await Future<void>.delayed(Duration.zero);
    expect(calls, 2);
    expect(c.read(ownerPendingRequestsCountProvider), 2);
  });

  test('an old session response cannot overwrite logout state', () async {
    final response = Completer<NavigationCounts>();
    final c = container(() => response.future);
    c.read(navigationCountsProvider);
    await Future<void>.delayed(Duration.zero);
    c.updateOverrides([
      authenticatedSessionScopeKeyProvider.overrideWithValue(null),
      navigationCountsLoaderProvider.overrideWithValue(() => response.future),
    ]);
    expect(c.read(navigationCountsProvider).valueOrNull?.pendingRequests, 0);
    response.complete(const NavigationCounts(pendingRequests: 99));
    await Future<void>.delayed(Duration.zero);
    expect(c.read(ownerPendingRequestsCountProvider), 0);
  });
}
