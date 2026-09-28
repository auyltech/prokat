import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/catalog/models/catalog_group.dart';
import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/features/categories/widgets/catalog_group_tabs.dart';
import 'package:prokat/features/equipment/providers/equipment_mutation_provider.dart';
import 'package:prokat/features/equipment_demand/equipment_demand_models.dart';
import 'package:prokat/features/equipment_demand/equipment_demand_provider.dart';
import 'package:prokat/features/requests/providers/request_mutation_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

enum CategorySheetMode {
  selectCategory,
  createRequest,
  createBooking,
  createEquipment,
  editEquipment,
}

class CategorySelectionSheet extends ConsumerWidget {
  final CategorySheetMode service;
  const CategorySelectionSheet({super.key, required this.service});

  static Future<Category?> show(
    BuildContext context, {
    required CategorySheetMode service,
  }) async {
    return await showModalBottomSheet<Category?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CategorySelectionSheet(service: service),
    );
  }

  bool get _isOwnerMutation =>
      service == CategorySheetMode.createEquipment ||
      service == CategorySheetMode.editEquipment;

  bool get _isMutation =>
      service == CategorySheetMode.createRequest ||
      service == CategorySheetMode.createEquipment ||
      service == CategorySheetMode.editEquipment;

  List<CatalogGroup> _availableGroups(WidgetRef ref) {
    final catalog = ref.watch(catalogProvider).valueOrNull;
    return _isOwnerMutation
        ? ownerVisibleCatalogGroups(catalog)
        : userVisibleCatalogGroups(catalog);
  }

  List<Category> _categoriesForSheet(WidgetRef ref, CatalogGroup group) {
    final catalog = ref.watch(catalogProvider).valueOrNull;
    if (_isOwnerMutation) {
      return catalog
              ?.ownerCategoriesFor(group)
              .map(Category.fromCatalog)
              .toList() ??
          const [];
    }

    final items = ref.watch(categoriesProvider).valueOrNull?.items ?? const [];
    return items.where((item) => item.catalogGroup == group).toList();
  }

  Future<void> _openSuggestEquipment(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final router = GoRouter.of(context);

    DemandConfig? config = ref.read(demandConfigProvider).valueOrNull;
    if (config == null || !config.shouldShow) {
      try {
        config = await ref.read(demandConfigProvider.future);
      } catch (_) {
        config = null;
      }
    }

    if (!context.mounted) return;
    Navigator.of(context).pop();

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

    await router.push(AppRoutes.equipmentDemandPath(campaignId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final groups = _availableGroups(ref);
    final selectedGroup = coerceCatalogGroup(
      ref.watch(mutationCatalogGroupProvider),
      groups,
    );
    final categories = _categoriesForSheet(ref, selectedGroup);
    final demandEligible =
        service == CategorySheetMode.createEquipment ||
        service == CategorySheetMode.createRequest;
    final showSuggest =
        demandEligible &&
        (ref.watch(demandConfigProvider).valueOrNull?.shouldShow ?? false);
    final itemCount = categories.length + (showSuggest ? 1 : 0);
    final sheetTitle = service == CategorySheetMode.createRequest
        ? l10n.requestCategoryTitle
        : l10n.selectService;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          Text(sheetTitle, style: theme.textTheme.titleLarge),

          if (_isMutation) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: CatalogGroupTabs(
                groups: groups,
                selected: selectedGroup,
                onChanged: (group) {
                  ref.read(mutationCatalogGroupProvider.notifier).select(group);
                  if (service == CategorySheetMode.createRequest) {
                    ref.read(requestMutationProvider.notifier).clearCategory();
                  } else if (service == CategorySheetMode.createEquipment) {
                    ref
                        .read(equipmentMutationProvider.notifier)
                        .clearCategory();
                  }
                },
              ),
            ),
          ],

          const SizedBox(height: 16),

          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: itemCount,
              itemBuilder: (context, index) {
                if (showSuggest && index == categories.length) {
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 4,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      l10n.demandSurveyCardTitle,
                      style: theme.textTheme.bodyLarge,
                    ),
                    onTap: () => _openSuggestEquipment(context, ref, l10n),
                  );
                }

                final category = categories[index];

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 4,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.construction_rounded,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    category.localizedName(
                      Localizations.localeOf(context).languageCode,
                    ),
                    style: theme.textTheme.bodyLarge,
                  ),
                  trailing: service == CategorySheetMode.createRequest
                      ? Icon(
                          Icons.check_rounded,
                          color: theme.colorScheme.primary,
                        )
                      : null,
                  onTap: () {
                    if (service == CategorySheetMode.createRequest) {
                      Navigator.pop(context, category);
                      return;
                    }
                    if (service == CategorySheetMode.createEquipment ||
                        service == CategorySheetMode.editEquipment) {
                      ref
                          .read(equipmentMutationProvider.notifier)
                          .selectCategory(category);
                    }

                    Navigator.pop(context, category);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
