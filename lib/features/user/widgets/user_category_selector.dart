import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/appstatic/widgets/category_card.dart';
import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/categories/providers/category_provider.dart';
import 'package:prokat/features/categories/widgets/empty_categories_tile.dart';
import 'package:prokat/features/categories/widgets/error_categories_tile.dart';
import 'package:prokat/features/user/state/user_profile_provider.dart';
import 'package:go_router/go_router.dart';

class UserCategorySelector extends ConsumerStatefulWidget {
  const UserCategorySelector({super.key});

  @override
  ConsumerState<UserCategorySelector> createState() =>
      _UserCategorySelectorState();
}

class _UserCategorySelectorState extends ConsumerState<UserCategorySelector> {
  Future<void> onCategorySelected(
    BuildContext context,
    Category category,
  ) async {
    ref.read(categoriesProvider.notifier).selectCategory(category);
    final userProfileState = ref.read(userProfileProvider.notifier);

    await userProfileState.selectCategory(category.id);

    if (context.mounted) {
      final uri = Uri(
        path: AppRoutes.searchList,
        queryParameters: {'category': category.id},
      ).toString();
      context.push(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(categoriesProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Services", // More engaging title
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
          ),
        ),

        if (categoriesState.isLoading)
          const EmptyCategoriesCard()
        else if (categoriesState.error != null)
          const ErrorCategoriesCard()
        else if (categoriesState.categories.isEmpty)
          const EmptyCategoriesCard()
        else
          SizedBox(
            height: 140, // Slightly shorter for better vertical rhythm
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categoriesState.categories.length,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final cat = categoriesState.categories[index];
                final isSelected =
                    categoriesState.selectedCategory?.id == cat.id;

                return CategoryCard(
                  category: cat,
                  onTap: () => onCategorySelected(context, cat),
                  isSelected: isSelected,
                );
              },
            ),
          ),
      ],
    );
  }
}
