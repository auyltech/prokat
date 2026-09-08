import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/categories/state/categories_notifier.dart';

export 'category_dependencies.dart' show categoryServiceProvider;

final categoriesProvider =
    AsyncNotifierProvider<CategoriesNotifier, QueryState<Category>>(
      CategoriesNotifier.new,
    );

final selectedCategoryProvider =
    NotifierProvider<SelectedCategoryNotifier, Category?>(
      SelectedCategoryNotifier.new,
    );

class SelectedCategoryNotifier extends Notifier<Category?> {
  @override
  Category? build() => null;

  void select(Category? category) => state = category;

  void toggle(Category category) {
    state = state?.id == category.id ? null : category;
  }

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
