import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/core/widgets/section_title.dart';
import 'package:prokat/features/appstatic/widgets/category_card.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/features/categories/widgets/category_row_skeleton.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/equipment_demand/equipment_demand_models.dart';
import 'package:prokat/features/equipment_demand/equipment_demand_provider.dart';

class GuestCategorySection extends ConsumerStatefulWidget {
  const GuestCategorySection({super.key});

  @override
  ConsumerState<GuestCategorySection> createState() =>
      _GuestCategorySectionState();
}

class _GuestCategorySectionState extends ConsumerState<GuestCategorySection> {
  static const _tileExtent = 132.0;
  static const _tileWidth = 140.0;
  static const _tileSpacing = 12.0;

  Future<void> _openSuggestEquipment() async {
    final l10n = AppLocalizations.of(context)!;
    DemandConfig? config = ref.read(demandConfigProvider).valueOrNull;
    if (config == null || !config.shouldShow) {
      try {
        config = await ref.read(demandConfigProvider.future);
      } catch (_) {
        config = null;
      }
    }
    if (!mounted) return;
    final campaignId = config?.campaignId;
    if (campaignId == null ||
        campaignId.isEmpty ||
        !(config?.shouldShow ?? false)) {
      AppToast.show(
        message: l10n.demandSurveyLoadError,
        type: AppToastType.error,
      );
      return;
    }
    await context.push(AppRoutes.equipmentDemandPath(campaignId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final categoriesAsync = ref.watch(categoriesProvider);
    final categories = categoriesAsync.valueOrNull?.items ?? const [];
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final showDemand =
        ref.watch(demandConfigProvider).valueOrNull?.shouldShow ?? false;
    final totalItemCount = categories.length + (showDemand ? 1 : 0);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SectionTitle(title: l10n.services),
          ),
          const SizedBox(height: 12),
          if (categoriesAsync.isLoading && categories.isEmpty && !showDemand)
            const CategoryRowSkeleton(
              padding: EdgeInsets.symmetric(horizontal: 16),
            )
          else if (categoriesAsync.hasError &&
              categories.isEmpty &&
              !showDemand)
            EmptyStateTile(
              icon: LucideIcons.router,
              title: l10n.errorLoadingServices,
              subtitle: l10n.couldNotLoadServices,
            )
          else
            SizedBox(
              height: _tileExtent,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: totalItemCount,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: _tileSpacing),
                itemBuilder: (context, i) {
                  if (showDemand && i == categories.length) {
                    return SizedBox(
                      width: _tileWidth,
                      child: DemandCategoryCard(
                        title: l10n.demandSurveyCardTitle,
                        onTap: _openSuggestEquipment,
                      ),
                    );
                  }
                  final category = categories[i];

                  return SizedBox(
                    width: _tileWidth,
                    child: CategoryCard(
                      isSelected: selectedCategory?.id == category.id,
                      category: category,
                      onTap: () => ref
                          .read(selectedCategoryProvider.notifier)
                          .toggle(category),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
