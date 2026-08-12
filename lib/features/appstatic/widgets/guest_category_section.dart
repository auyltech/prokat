import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    final categoriesAsync = ref.watch(categoriesProvider);
    final categories = categoriesAsync.valueOrNull?.items ?? const [];
    final selectedCategory = ref.watch(selectedCategoryProvider);

    const int columns = 3;
    final int rowCount = (categories.length / columns).ceil();

    // Explicit double calculations to fix typing warnings
    final double gridHeight = rowCount > 0
        ? (rowCount * 110.0) + ((rowCount - 1) * 10.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Services Header Title
          SectionTitle(title: l10n.services),

          const SizedBox(height: 12),

          // Categories / Services Grid Area
          if (categoriesAsync.isLoading && categories.isEmpty)
            const CategoryRowSkeleton()
          else if (categoriesAsync.hasError && categories.isEmpty)
            EmptyStateTile(
              icon: LucideIcons.router,
              title: l10n.errorLoadingServices,
              subtitle: l10n.couldNotLoadServices,
            )
          else if (categories.isEmpty)
            EmptyStateTile(
              icon: LucideIcons.box,
              title: l10n.noServicesFound,
              subtitle: l10n.noServicesAvailable,
            )
          else
            SizedBox(
              height: gridHeight,
              child: GridView.builder(
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 10.0,
                  crossAxisSpacing: 10.0,
                  mainAxisExtent:
                      110.0, // Matches your gridHeight calculation math
                ),
                itemBuilder: (context, i) {
                  final category = categories[i];

                  return CategoryCard(
                    isSelected: selectedCategory?.id == category.id,
                    category: category,
                    onTap: () => ref
                        .read(selectedCategoryProvider.notifier)
                        .select(category),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
