import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/categories/state/category_service.dart';
import 'package:prokat/features/categories/state/categories_state.dart';
import 'package:prokat/features/user/state/user_profile_provider.dart';

class CategoriesNotifier extends StateNotifier<CategoryState> {
  Ref ref;
  final CategoryService service;

  CategoriesNotifier(this.service, this.ref) : super(CategoryState());

  void selectCategory(Category? category) {
    state = state.copyWith(selectedCategory: category, showSelect: false);
  }

  void selectCategoryById(String? categoryId) {
    Category? foundCategory;

    if (categoryId != null) {
      foundCategory = state.categories
          .where((item) => item.id == categoryId)
          .firstOrNull;
    }

    if (foundCategory != null) {
      state = state.copyWith(
        selectedCategory: foundCategory,
        showSelect: false,
      );
    }
  }

  void clearCategory() {
    state = state.copyWith(showSelect: true);
  }

  Future<void> getCategories() async {
    try {
      state = state.copyWith(isLoading: true);

      final result = await service.getCategories();

      state = state.copyWith(
        isLoading: false,
        categories: result.data,
        error: result.success ? null : result.message,
        isSuccess: (result.success && result.data?.isNotEmpty == true)
            ? true
            : false,
        lastSuccess: (result.success && result.data?.isNotEmpty == true)
            ? DateTime.now()
            : null,
      );

      if (result.success) {
        final selectedCategoryId = ref
            .read(userProfileProvider)
            .userProfile
            ?.selectedCategoryId;

        selectCategoryById(selectedCategoryId);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        isSuccess: false,
        lastSuccess: null,
      );
    }
  }
}
