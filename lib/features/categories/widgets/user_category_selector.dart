import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/features/appstatic/widgets/category_card.dart';
import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/features/categories/widgets/category_row_skeleton.dart';
import 'package:prokat/features/user/state/user_profile_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

class UserCategorySelector extends ConsumerStatefulWidget {
  final String mode;

  const UserCategorySelector({super.key, required this.mode});

  @override
  ConsumerState<UserCategorySelector> createState() =>
      _UserCategorySelectorState();
}

class _UserCategorySelectorState extends ConsumerState<UserCategorySelector> {
  // Handle submit
  Future<void> onCategorySelected(
    BuildContext context,
    Category category,
  ) async {
    ref.read(categoriesProvider.notifier).selectCategory(category);

    final userProfileState = ref.read(userProfileProvider.notifier);

    await userProfileState.selectCategory(category.id);
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(categoriesProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.services,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
          ),
        ),

        SizedBox(height: 8),

        if (categoriesState.isLoading)
          const CategoryRowSkeleton()
        else if (categoriesState.error != null)
          const EmptyStateTile(
            title: "Error",
            subtitle: "Could not load services",
          )
        else if (categoriesState.categories.isEmpty)
          const EmptyStateTile(
            title: "No services found",
            subtitle: "There are no services listed at the moment",
          )
        else
          SizedBox(
            height: 110,
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
