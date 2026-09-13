import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/features/appstatic/widgets/category_card.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/features/categories/vacuum_trucks.dart';
import 'package:prokat/features/categories/widgets/category_row_skeleton.dart';
import 'package:prokat/features/requests/providers/request_mutation_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/features/equipment_demand/equipment_demand_provider.dart';

class UserCategorySelector extends ConsumerStatefulWidget {
  final String mode;
  final String? selectedCategoryId;

  const UserCategorySelector({
    super.key,
    required this.mode,
    this.selectedCategoryId,
  });

  @override
  ConsumerState<UserCategorySelector> createState() =>
      _UserCategorySelectorState();
}

class _UserCategorySelectorState extends ConsumerState<UserCategorySelector> {
  void onCategorySelected(BuildContext context, Category category) {
    if (widget.mode == "create_request") {
      ref.read(requestMutationProvider.notifier).selectCategory(category);
      return;
    }

    if (widget.mode == "search") {
      ref.read(selectedCategoryProvider.notifier).toggle(category);
    }
  }

  Future<void> _openSuggestEquipment() async {
    final l10n = AppLocalizations.of(context)!;
    final campaignId = ref.read(demandConfigProvider).valueOrNull?.campaignId;
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            height: 132,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length + 1,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                if (index == categories.length) {
                  return SizedBox(
                    width: 140,
                    child: DemandCategoryCard(
                      title: l10n.demandSurveyCardTitle,
                      onTap: _openSuggestEquipment,
                    ),
                  );
                }
                final cat = categories[index];
                final isSelected = widget.selectedCategoryId == cat.id;

                return SizedBox(
                  width: 140,
                  child: CategoryCard(
                    category: cat,
                    onTap: () => onCategorySelected(context, cat),
                    isSelected: isSelected,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
