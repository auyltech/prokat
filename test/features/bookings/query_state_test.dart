import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/bookings/models/query_state.dart';

void main() {
  group('QueryState', () {
    test('copyWith retains omitted timestamp and clears it functionally', () {
      final fetchedAt = DateTime(2026, 1, 2);
      final state = QueryState<int>(
        items: const [1],
        itemsPerPage: 20,
        count: 1,
        lastFetchedAt: fetchedAt,
      );

      expect(state.copyWith().lastFetchedAt, same(fetchedAt));
      expect(state.copyWith(lastFetchedAt: () => null).lastFetchedAt, isNull);
    });

    test('refresh errors preserve data and successful timestamps', () {
      final fetchedAt = DateTime(2026, 1, 2);
      final state = QueryState<int>(
        items: const [1, 2],
        itemsPerPage: 20,
        count: 2,
        lastFetchedAt: fetchedAt,
        isRefreshing: true,
      );

      final failed = state.withRefreshError(Exception('offline'));

      expect(failed.items, [1, 2]);
      expect(failed.lastFetchedAt, same(fetchedAt));
      expect(failed.isRefreshing, isFalse);
      expect(failed.refreshError?.message, contains('offline'));
      expect(failed.copyWith().refreshError, same(failed.refreshError));
      expect(failed.copyWith(refreshError: () => null).refreshError, isNull);
    });

    test('supports custom TTL while retaining the 30 second default', () {
      final state = QueryState<int>(
        itemsPerPage: 20,
        count: 0,
        lastFetchedAt: DateTime.now().subtract(const Duration(minutes: 2)),
      );

      expect(state.isStale, isTrue);
      expect(state.isStaleAfter(const Duration(hours: 1)), isFalse);
      expect(
        state
            .copyWith(lastFetchedAt: () => null)
            .isStaleAfter(const Duration(days: 1)),
        isTrue,
      );
    });
  });
}
