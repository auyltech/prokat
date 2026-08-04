import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/api/api_provider.dart';
import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/categories/state/categories_notifier.dart';
import 'package:prokat/features/categories/state/category_service.dart';

final categoryServiceProvider = Provider<CategoryService>((ref) {
  return CategoryService(ref.watch(apiClientProvider));
});

final categoriesProvider =
    AsyncNotifierProvider<CategoriesNotifier, QueryState<Category>>(
      CategoriesNotifier.new,
    );

final selectedCategoryProvider =
    NotifierProvider<SelectedCategoryNotifier, Category?>(
      SelectedCategoryNotifier.new,
    );
