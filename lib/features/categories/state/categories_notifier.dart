import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/api/fetch_status.dart';
import 'package:prokat/core/errors/app_error.dart';
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
      final hasData = state.categories.isNotEmpty;

      state = state.copyWith(
        fetchStatus: hasData ? FetchStatus.refreshing : FetchStatus.loading,
        fetchError: null,
      );

      final result = await service.getCategories();

      state = state.copyWith(
        categories: result.data,
        fetchStatus: result.data == null
            ? FetchStatus.error
            : result.data?.isEmpty == true
            ? FetchStatus.empty
            : FetchStatus.success,
        lastFetchedAt: DateTime.now(),
        fetchError: result.success
            ? null
            : AppError(
                type: ErrorType.unknown,
                message: result.error.toString(),
                code: "CATEGORY_FETCH_FAILED",
              ),
      );

      if (result.success) {
        final selectedCategoryId = ref
            .read(userProfileProvider)
            .userProfile
            ?.selectedCategoryId;

        selectCategoryById(selectedCategoryId);
      }
    } catch (error) {
      state = state.copyWith(
        fetchStatus: state.categories.isEmpty
            ? FetchStatus.error
            : FetchStatus.success,
        fetchError: AppError(
          type: ErrorType.unknown,
          message: error.toString(),
          code: "CATEGORY_FETCH_FAILED",
        ),
      );
    }
  }
}
