import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/core/widgets/section_title.dart';
import 'package:prokat/features/appstatic/widgets/category_card.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/features/categories/vacuum_trucks.dart';
import 'package:prokat/features/categories/widgets/category_row_skeleton.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/features/equipment_demand/equipment_demand_provider.dart';

class GuestCategorySection extends ConsumerStatefulWidget {
  const GuestCategorySection({super.key});

  @override
  ConsumerState<GuestCategorySection> createState() =>
      _GuestCategorySectionState();
}

class _GuestCategorySectionState extends ConsumerState<GuestCategorySection> {
  static const _tileExtent = 132.0;

  Future<void> _openSuggestEquipment() async {
    final l10n = AppLocalizations.of(context)!;
    final config = ref.read(demandConfigProvider).valueOrNull;
    final campaignId = config?.campaignId;
    if (campaignId == null || campaignId.isEmpty) {
      AppSnackBar.show(message: l10n.demandSurveyLoadError, isError: true);
      return;
    }
    await context.push(AppRoutes.equipmentDemandPath(campaignId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final catalogAsync = ref.watch(catalogProvider);
    final categories = vacuumTrucksCategories(catalogAsync.valueOrNull);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final totalItemCount = categories.length + 1;

    const int columns = 2;
    final int rowCount = (totalItemCount / columns).ceil();
    final double gridHeight = rowCount > 0
        ? (rowCount * _tileExtent) + ((rowCount - 1) * 10.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SectionTitle(title: l10n.services),
          const SizedBox(height: 12),
          if (catalogAsync.isLoading && categories.isEmpty)
            const CategoryRowSkeleton()
          else if (catalogAsync.hasError && categories.isEmpty)
            EmptyStateTile(
              icon: LucideIcons.router,
              title: l10n.errorLoadingServices,
              subtitle: l10n.couldNotLoadServices,
            )
          else
            SizedBox(
              height: gridHeight,
              child: GridView.builder(
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: totalItemCount,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 10.0,
                  crossAxisSpacing: 10.0,
                  mainAxisExtent: _tileExtent,
                ),
                itemBuilder: (context, i) {
                  if (i == categories.length) {
                    return DemandCategoryCard(
                      title: l10n.demandSurveyCardTitle,
                      onTap: _openSuggestEquipment,
                    );
                  }
                  final category = categories[i];

                  return CategoryCard(
                    isSelected: selectedCategory?.id == category.id,
                    category: category,
                    onTap: () => ref
                        .read(selectedCategoryProvider.notifier)
                        .toggle(category),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
