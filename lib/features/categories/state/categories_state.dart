import 'package:prokat/core/api/fetch_status.dart';
import 'package:prokat/core/errors/app_error.dart';
import 'package:prokat/core/mutation/mutation_model.dart';
import 'package:prokat/features/categories/models/category.dart';

class CategoryState {
  final FetchStatus fetchStatus;
  final PaginationStatus paginationStatus;

  final DateTime? lastFetchedAt;
  final AppError? fetchError;

  final Set<Mutation> activeActions;

  final List<Category> categories;
  final Category? selectedCategory;

  final bool? showSelect;

  CategoryState({
    this.fetchStatus = FetchStatus.initial,
    this.paginationStatus = PaginationStatus.idle,
    this.lastFetchedAt,
    this.fetchError,
    this.activeActions = const {},

    this.selectedCategory,
    this.showSelect,
    this.categories = const [],
  });

  Category? getCategoryById(String? categoryId) {
    if (categoryId == null) return null;

    final foundCategory = categories
        .where((item) => item.id == categoryId)
        .firstOrNull;

    return foundCategory;
  }

  CategoryState copyWith({
    FetchStatus? fetchStatus,
    PaginationStatus? paginationStatus,
    DateTime? lastFetchedAt,
    AppError? fetchError,
    Set<Mutation>? activeActions,
    List<Category>? categories,
    Category? selectedCategory,
    bool? showSelect,
  }) {
    return CategoryState(
      fetchStatus: fetchStatus ?? this.fetchStatus,
      paginationStatus: paginationStatus ?? this.paginationStatus,
      lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
      fetchError: fetchError,
      activeActions: activeActions ?? this.activeActions,

      categories: categories ?? this.categories,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      showSelect: showSelect ?? this.showSelect,
    );
  }
}
