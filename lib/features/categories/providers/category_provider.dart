import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/categories/state/categories_notifier.dart';
import 'package:prokat/features/categories/state/categories_state.dart';
import '../../../core/providers/api_provider.dart';
import '../state/category_service.dart';

final categoryServiceProvider = Provider<CategoryService>((ref) {
  final dio = ref.watch(apiClientProvider);

  return CategoryService(dio);
});

final categoriesProvider =
    StateNotifierProvider<CategoriesNotifier, CategoryState>((ref) {
      final service = ref.watch(categoryServiceProvider);

      return CategoriesNotifier(service);
    });
