import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/api/fetch_status.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/core/widgets/section_title.dart';
import 'package:prokat/features/appstatic/widgets/category_card.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/features/categories/widgets/category_row_skeleton.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:lucide_icons/lucide_icons.dart';

class GuestCategorySection extends ConsumerStatefulWidget {
  const GuestCategorySection({super.key});

  @override
  ConsumerState<GuestCategorySection> createState() =>
      _GuestCategorySectionState();
}

class _GuestCategorySectionState extends ConsumerState<GuestCategorySection> {
  @override
  Widget build(BuildContext context) {
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Services Header Title
          SectionTitle(title: l10n.services),

          const SizedBox(height: 12),

          // Categories / Services Grid Area
          if (categoriesState.fetchStatus == FetchStatus.loading)
            const CategoryRowSkeleton()
          else if (categoriesState.fetchStatus == FetchStatus.error)
            const EmptyStateTile(
              icon: LucideIcons.router,
              title: "Error Loading Services",
              subtitle: "Could not load services",
            )
          else if (categoriesState.fetchStatus == FetchStatus.empty)
            const EmptyStateTile(
              icon: LucideIcons.box,
              title: "No Services Found",
              subtitle: "There are no services listed at the moment",
            )
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
