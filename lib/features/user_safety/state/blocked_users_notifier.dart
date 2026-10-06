import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/auth/providers/authenticated_session_scope.dart';
import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/user_safety/models/blocked_user.dart';
import 'package:prokat/features/user_safety/state/user_safety_providers.dart';

class BlockedUsersNotifier extends AsyncNotifier<QueryState<BlockedUser>> {
  static const _itemsPerPage = 20;

  @override
  Future<QueryState<BlockedUser>> build() async {
    final scope = ref.watch(authenticatedSessionScopeKeyProvider);
    if (scope == null) {
      return const QueryState(itemsPerPage: _itemsPerPage, count: 0);
    }
    return _fetchPage(1);
  }

  Future<QueryState<BlockedUser>> _fetchPage(int page) async {
    final response = await ref
        .read(userSafetyServiceProvider)
        .getBlockedUsers(page: page, itemsPerPage: _itemsPerPage);
    final items = response.data;
    if (!response.success || items == null) {
      throw Exception(response.message);
    }
    return QueryState(
      items: items,
      page: page,
      itemsPerPage: _itemsPerPage,
      count: response.count ?? items.length,
      lastFetchedAt: DateTime.now(),
    );
  }

  Future<void> refresh() async {
    final previous = state.valueOrNull;
    if (previous == null) {
      state = const AsyncLoading();
      state = await AsyncValue.guard(() => _fetchPage(1));
      return;
    }
    state = AsyncData(previous.copyWith(isRefreshing: true));
    try {
      state = AsyncData(await _fetchPage(1));
    } catch (error) {
      state = AsyncData(previous.withRefreshError(error));
    }
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null ||
        !current.hasMore ||
        current.isLoadingMore ||
        current.isRefreshing) {
      return;
    }
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final next = await _fetchPage(current.page + 1);
      state = AsyncData(
        next.copyWith(items: [...current.items, ...next.items]),
      );
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  void removeLocally(String userId) {
    final current = state.valueOrNull;
    if (current == null) return;
    final kept = current.items.where((item) => item.userId != userId).toList();
    final removed = current.items.length - kept.length;
    if (removed == 0) return;
    state = AsyncData(
      current.copyWith(
        items: kept,
        count: (current.count - removed).clamp(0, current.count),
      ),
    );
  }
}
