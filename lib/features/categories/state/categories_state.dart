import 'package:prokat/features/categories/models/category.dart';

class CategoryState {
  final bool isLoading;

  final bool? isSuccess;
  final DateTime? lastSuccess;

  final String? error;

  final List<Category> categories;
  final Category? selectedCategory;

  final bool? showSelect;

  CategoryState({
    this.isLoading = false,
    this.isSuccess = false,
    this.lastSuccess,
    this.error,
    this.selectedCategory,
    this.showSelect,
    this.categories = const [],
  });

  CategoryState copyWith({
    bool? isLoading,
    bool? isSuccess,
    DateTime? lastSuccess,
    String? error,
    List<Category>? categories,
    Category? selectedCategory,
    bool? showSelect,
  }) {
    return CategoryState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      lastSuccess: lastSuccess ?? this.lastSuccess,
      error: error,
      categories: categories ?? this.categories,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      showSelect: showSelect ?? this.showSelect,
    );
  }
}
