import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/section_title.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/categories/state/browse_group_session.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/features/categories/widgets/catalog_group_tabs.dart';
import 'package:prokat/features/categories/widgets/category_header_card.dart';
import 'package:prokat/features/appstatic/widgets/category_card.dart';
import 'package:prokat/l10n/app_localizations.dart';
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

    final catalog = ref.watch(catalogProvider).valueOrNull;
    final groups = userVisibleCatalogGroups(catalog);
    final group = coerceCatalogGroup(
      ref.watch(browseCatalogGroupProvider),
      groups,
    );
    final showDemand =
        ref.watch(demandConfigProvider).valueOrNull?.shouldShow ?? false;

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CatalogGroupTabs(
              groups: groups,
              selected: group,
              onChanged: (next) {
                ref.read(browseGroupSessionsProvider.notifier).ensure(next);
                ref.read(browseCatalogGroupProvider.notifier).select(next);
              },
            ),
          ),
          if (groups.length > 1) const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: CategoryHeaderCard(),
          ),
          if (showDemand) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 132,
                width: 140,
                child: DemandCategoryCard(
                  title: l10n.demandSurveyCardTitle,
                  onTap: _openSuggestEquipment,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
