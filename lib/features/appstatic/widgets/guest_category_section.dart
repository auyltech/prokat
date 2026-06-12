import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/features/appstatic/widgets/category_card.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

class GuestCategorySection extends ConsumerStatefulWidget {
  const GuestCategorySection({super.key});

  @override
  ConsumerState<GuestCategorySection> createState() =>
      _GuestCategorySectionState();
}

class _GuestCategorySectionState extends ConsumerState<GuestCategorySection> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final categoriesState = ref.watch(categoriesProvider);
    final selectedCategory = categoriesState.selectedCategory;

    const int columns = 3;
    final int rowCount = (categoriesState.categories.length / columns).ceil();

    // Explicit double calculations to fix typing warnings
    final double gridHeight = rowCount > 0
        ? (rowCount * 110.0) + ((rowCount - 1) * 10.0)
        : 0.0;

    return Container(
      color: theme
          .scaffoldBackgroundColor, // Ensures scrolling items underneath don't blend
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Services Header Title
          Text(
            l10n.services,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          // Categories / Services Grid Area
          if (categoriesState.isLoading && categoriesState.categories.isEmpty)
            EmptyStateTile(title: l10n.loading)
          else if (categoriesState.error != null)
            EmptyStateTile(title: l10n.errorLoadingServices)
          else
            SizedBox(
              height: gridHeight,
              child: GridView.builder(
                padding: EdgeInsets.zero,
                physics:
                    const NeverScrollableScrollPhysics(), // Disables nested scrolling
                itemCount: categoriesState.categories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 10.0,
                  crossAxisSpacing: 10.0,
                  mainAxisExtent:
                      110.0, // Matches your gridHeight calculation math
                ),
                itemBuilder: (context, i) {
                  final category = categoriesState.categories[i];

                  return CategoryCard(
                    isSelected: selectedCategory?.id == category.id,
                    category: category,
                    onTap: () => ref
                        .read(categoriesProvider.notifier)
                        .selectCategory(category),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
