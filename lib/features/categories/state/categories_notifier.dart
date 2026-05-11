import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/categories/state/category_service.dart';
import 'package:prokat/features/categories/state/categories_state.dart';

class CategoriesNotifier extends StateNotifier<CategoryState> {
  final CategoryService service;

  CategoriesNotifier(this.service) : super(CategoryState()) {
    // getCategories();
  }

  void selectCategory(Category? category) {
    state = state.copyWith(selectedCategory: category, showSelect: false);
  }

  void clearCategory() {
    state = state.copyWith(showSelect: true);
  }

  Future<void> getCategories() async {
    try {
      state = state.copyWith(isLoading: true);

      final result = await service.getCategories();

      if (result.success) {
        state = state.copyWith(isLoading: false, categories: result.data);
      } else {
        state = state.copyWith(isLoading: false, error: result.error);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
