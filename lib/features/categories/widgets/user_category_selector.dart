import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/features/appstatic/widgets/category_card.dart';
import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/features/categories/widgets/category_row_skeleton.dart';
import 'package:prokat/features/requests/providers/request_mutation_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/equipment_demand/equipment_demand_models.dart';
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
  static const _horizontalBleed = 16.0;
  static const _tileExtent = 132.0;
  static const _tileWidth = 140.0;
  static const _tileSpacing = 12.0;

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
    final showDemand =
        ref.watch(demandConfigProvider).valueOrNull?.shouldShow ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (categoriesAsync.isLoading && categories.isEmpty && !showDemand)
          const _FullWidthCategoryRow(
            child: CategoryRowSkeleton(
              padding: EdgeInsets.symmetric(horizontal: _horizontalBleed),
            ),
          )
        else if (categoriesAsync.hasError && categories.isEmpty && !showDemand)
          EmptyStateTile(
            icon: LucideIcons.router,
            title: l10n.errorLoadingServices,
            subtitle: l10n.couldNotLoadServices,
          )
        else
          _FullWidthCategoryRow(
            child: SizedBox(
              height: _tileExtent,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length + (showDemand ? 1 : 0),
                padding: const EdgeInsets.symmetric(
                  horizontal: _horizontalBleed,
                ),
                separatorBuilder: (context, index) =>
                    const SizedBox(width: _tileSpacing),
                itemBuilder: (context, index) {
                  if (showDemand && index == categories.length) {
                    return SizedBox(
                      width: _tileWidth,
                      child: DemandCategoryCard(
                        title: l10n.demandSurveyCardTitle,
                        onTap: _openSuggestEquipment,
                      ),
                    );
                  }
                  final cat = categories[index];
                  final isSelected = widget.selectedCategoryId == cat.id;

                  return SizedBox(
                    width: _tileWidth,
                    child: CategoryCard(
                      category: cat,
                      onTap: () => onCategorySelected(context, cat),
                      isSelected: isSelected,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _FullWidthCategoryRow extends StatelessWidget {
  final Widget child;

  const _FullWidthCategoryRow({required this.child});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return SizedBox(
      height: _UserCategorySelectorState._tileExtent,
      child: Transform.translate(
        offset: const Offset(-_UserCategorySelectorState._horizontalBleed, 0),
        child: OverflowBox(
          alignment: Alignment.centerLeft,
          maxWidth: screenWidth,
          child: SizedBox(width: screenWidth, child: child),
        ),
      ),
    );
  }
}
