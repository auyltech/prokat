import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/features/categories/state/category_service.dart';

class CategoriesNotifier extends AsyncNotifier<QueryState<Category>> {
  static const staleAfter = Duration(hours: 24);

  late final CategoryService service;
  Future<void>? _refreshing;

  @override
  Future<QueryState<Category>> build() async {
    service = ref.read(categoryServiceProvider);
    return _fetch();
  }

  Future<QueryState<Category>> _fetch() async {
    final result = await service.getCategories();
    if (!result.success || result.data == null) {
      throw Exception(result.message);
    }

    final items = result.data!;
    return QueryState(
      items: items,
      page: 1,
      itemsPerPage: items.isEmpty ? 1 : items.length,
      count: items.length,
      lastFetchedAt: DateTime.now(),
    );
  }

  Future<void> refresh() {
    final active = _refreshing;
    if (active != null) return active;
    final operation = _refresh();
    _refreshing = operation;
    return operation.whenComplete(() => _refreshing = null);
  }

  Future<void> _refresh() async {
    final previous = state.value;
    if (previous == null) {
      if (state.isLoading) {
        try {
          await future;
          return;
        } catch (_) {}
      }
      state = const AsyncLoading();
      state = await AsyncValue.guard(_fetch);
      return;
    }

    state = AsyncData(previous.copyWith(isRefreshing: true));
    try {
      state = AsyncData(await _fetch());
    } catch (error) {
      state = AsyncData(previous.withRefreshError(error));
    }
  }

  Future<void> refreshIfStale() async {
    if (state.isLoading) {
      try {
        await future;
      } catch (_) {}
    }
    final current = state.value;
    if (current == null || current.isStaleAfter(staleAfter)) {
      await refresh();
    }
  }
}

class SelectedCategoryNotifier extends Notifier<Category?> {
  @override
  Category? build() => null;

  void select(Category? category) => state = category;

  void selectById(String? id) {
    if (id == null) {
      state = null;
      return;
    }
    final items = ref.read(categoriesProvider).valueOrNull?.items ?? const [];
    state = items.where((item) => item.id == id).firstOrNull;
  }

  void clear() => state = null;
}
