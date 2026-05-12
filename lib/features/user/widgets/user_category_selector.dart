import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/categories/providers/category_provider.dart';
import 'package:prokat/features/categories/widgets/empty_categories_tile.dart';
import 'package:prokat/features/categories/widgets/error_categories_tile.dart';
import 'package:prokat/features/categories/widgets/category_tile.dart';

class UserCategorySelector extends ConsumerWidget {
  const UserCategorySelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesState = ref.watch(categoriesProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
          child: Text(
            "Explore Services", // More engaging title
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
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

                return CategoryTile(cat: cat, isSelected: isSelected);
              },
            ),
          ),
      ],
    );
  }
}
