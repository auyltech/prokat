import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/features/categories/vacuum_trucks.dart';
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

  List<Category> _categoriesForSheet(WidgetRef ref) {
    if (service == CategorySheetMode.createEquipment) {
      final vacuum = vacuumTrucksCategory(
        ref.watch(catalogProvider).valueOrNull,
      );
      return vacuum == null ? const [] : [vacuum];
    }
    return ref.watch(categoriesProvider).valueOrNull?.items ?? const [];
  }

  Future<void> _openSuggestEquipment(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final router = GoRouter.of(context);

    DemandConfig? config = ref.read(demandConfigProvider).valueOrNull;
    if (config == null) {
      try {
        config = await ref.read(demandConfigProvider.future);
      } catch (_) {
        config = null;
      }
    }

    if (!context.mounted) return;
    Navigator.of(context).pop();

    final campaignId = config?.campaignId;
    if (campaignId == null || campaignId.isEmpty) {
      AppSnackBar.show(message: l10n.demandSurveyLoadError, isError: true);
      return;
    }

    await router.push(AppRoutes.equipmentDemandPath(campaignId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final categories = _categoriesForSheet(ref);
    final showSuggest = service == CategorySheetMode.createEquipment;
    final itemCount = categories.length + (showSuggest ? 1 : 0);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          Text(l10n.selectService, style: theme.textTheme.titleLarge),

          const SizedBox(height: 16),

          // List the categories
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
                        color: theme.colorScheme.onPrimary,
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
                      color: theme.colorScheme.onPrimary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    category.localizedName(
                      Localizations.localeOf(context).languageCode,
                    ),
                    style: theme.textTheme.bodyLarge,
                  ),
                  onTap: () {
                    if (service == CategorySheetMode.createRequest) {
                      // Update the Request Notifier
                      ref
                          .read(requestMutationProvider.notifier)
                          .selectCategory(category);
                    } else if (service == CategorySheetMode.createEquipment ||
                        service == CategorySheetMode.editEquipment) {
                      ref
                          .read(equipmentMutationProvider.notifier)
                          .selectCategory(category);
                    }

                    // Close the sheet and return the category to the form
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
