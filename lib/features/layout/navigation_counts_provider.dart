import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/api/api_provider.dart';
import 'package:prokat/features/auth/providers/authenticated_session_scope.dart';

class NavigationCounts {
  final int pendingRequests, pendingOrders, clientUnread, ownerUnread;
  const NavigationCounts({
    this.pendingRequests = 0,
    this.pendingOrders = 0,
    this.clientUnread = 0,
    this.ownerUnread = 0,
  });
  factory NavigationCounts.fromJson(Map<String, dynamic> json) {
    int count(String key) {
      final value = json[key];
      if (value is! int || value < 0) {
        throw FormatException('Invalid counter: $key');
      }
      return value.toInt();
    }

    return NavigationCounts(
      pendingRequests: count('pendingRequests'),
      pendingOrders: count('pendingOrders'),
      clientUnread: count('clientUnread'),
      ownerUnread: count('ownerUnread'),
    );
  }
}

final navigationCountsLoaderProvider =
    Provider<Future<NavigationCounts> Function()>((ref) {
      final api = ref.watch(apiClientProvider);
      return () async {
        final response = await api.dio.get('/notifications/navigation-counts');
        return NavigationCounts.fromJson(
          Map<String, dynamic>.from(response.data['data'] as Map),
        );
      };
    });

final navigationCountsProvider =
    NotifierProvider<NavigationCountsNotifier, AsyncValue<NavigationCounts>>(
      NavigationCountsNotifier.new,
    );

class NavigationCountsNotifier extends Notifier<AsyncValue<NavigationCounts>> {
  Timer? _timer;
  int _epoch = 0;
  bool _running = false, _again = false;

  @override
  AsyncValue<NavigationCounts> build() {
    final scope = ref.watch(authenticatedSessionScopeKeyProvider);
    final epoch = ++_epoch;
    _running = false;
    _again = false;
    ref.onDispose(() {
      _timer?.cancel();
      _epoch++;
    });
    if (scope == null) return const AsyncData(NavigationCounts());
    unawaited(
      Future.microtask(() async {
        if (_epoch == epoch) await refresh();
      }),
    );
    return const AsyncLoading();
  }

  void scheduleRefresh() {
    // A busy chat must not postpone the refresh indefinitely.
    if (_timer?.isActive ?? false) return;
    _timer = Timer(const Duration(milliseconds: 250), refresh);
  }

  Future<void> refresh() async {
    if (ref.read(authenticatedSessionScopeKeyProvider) == null) return;
    if (_running) {
      _again = true;
      return;
    }
    _running = true;
    final epoch = _epoch;
    do {
      _again = false;
      try {
        final next = await ref.read(navigationCountsLoaderProvider)();
        if (epoch != _epoch) return;
        state = AsyncData(next);
      } catch (error, stack) {
        if (epoch != _epoch) return;
        state = AsyncError<NavigationCounts>(
          error,
          stack,
        ).copyWithPrevious(state);
      }
    } while (_again);
    _running = false;
  }
}

void refreshNavigationCounts(Ref ref) {
  if (ref.exists(navigationCountsProvider)) {
    ref.read(navigationCountsProvider.notifier).scheduleRefresh();
  }
}
