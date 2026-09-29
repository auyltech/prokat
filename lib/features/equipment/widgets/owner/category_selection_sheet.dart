import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/catalog/models/catalog_group.dart';
import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/features/categories/widgets/catalog_group_tabs.dart';
import 'package:prokat/features/equipment/providers/equipment_mutation_provider.dart';
import 'package:prokat/features/requests/providers/request_mutation_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

enum CategorySheetMode {
  selectCategory,
  createRequest,
  createBooking,
  createEquipment,
  editEquipment,
}

class CategorySelectionSheet {
  CategorySelectionSheet._();

  static bool _isOwnerMutation(CategorySheetMode service) =>
      service == CategorySheetMode.createEquipment ||
      service == CategorySheetMode.editEquipment;

  static bool _isMutation(CategorySheetMode service) =>
      service == CategorySheetMode.createRequest ||
      service == CategorySheetMode.createEquipment ||
      service == CategorySheetMode.editEquipment;

  static List<CatalogGroup> _availableGroups(
    WidgetRef ref,
    CategorySheetMode service,
  ) {
    final catalog = ref.read(catalogProvider).valueOrNull;
    return _isOwnerMutation(service)
        ? ownerVisibleCatalogGroups(catalog)
        : userVisibleCatalogGroups(catalog);
  }

  static List<Category> _categoriesForSheet(
    WidgetRef ref,
    CategorySheetMode service,
    CatalogGroup group,
  ) {
    final catalog = ref.read(catalogProvider).valueOrNull;
    if (_isOwnerMutation(service)) {
      return catalog
              ?.ownerCategoriesFor(group)
              .map(Category.fromCatalog)
              .toList() ??
          const [];
    }

    final items = ref.read(categoriesProvider).valueOrNull?.items ?? const [];
    return items.where((item) => item.catalogGroup == group).toList();
  }

  static Widget _categoryImage(Category category) {
    final url = category.imageUrl;
    if (url != null && url.isNotEmpty) {
      return OptimizedNetworkImage(
        imageUrl: url,
        fit: BoxFit.contain,
        height: 48,
        width: 48,
      );
    }
    return const Icon(Icons.image_not_supported, size: 32);
  }

  static Future<Category?> show(
    BuildContext context, {
    required CategorySheetMode service,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final sheetTitle = service == CategorySheetMode.createRequest
        ? l10n.requestCategoryTitle
        : l10n.selectService;

    return AppBottomSheet.showScrollable<Category?>(
      context,
      title: sheetTitle,
      initialChildSize: 0.4,
      minChildSize: 0.2,
      maxChildSize: 0.85,
      headerBuilder: (context) {
        if (!_isMutation(service)) {
          return const SizedBox.shrink();
        }

        return Consumer(
          builder: (context, ref, _) {
            final groups = _availableGroups(ref, service);
            final selectedGroup = coerceCatalogGroup(
              ref.watch(mutationCatalogGroupProvider),
              groups,
            );

            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
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
            );
          },
        );
      },
      scrollableListBuilder: (context, scrollController) {
        return Consumer(
          builder: (context, ref, _) {
            final locale = Localizations.localeOf(context).languageCode;
            final groups = _availableGroups(ref, service);
            final selectedGroup = coerceCatalogGroup(
              ref.watch(mutationCatalogGroupProvider),
              groups,
            );
            final categories = _categoriesForSheet(ref, service, selectedGroup);
            final selectedId = service == CategorySheetMode.createRequest
                ? ref.watch(requestMutationProvider).selectedCategory?.id
                : ref.watch(equipmentMutationProvider).category?.id;

            return ListView.builder(
              controller: scrollController,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];

                return _SelectionTile(
                  title: category.localizedName(locale),
                  description: category.localizedDescription(locale),
                  selected: selectedId == category.id,
                  image: _categoryImage(category),
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
            );
          },
        );
      },
      footerBuilder: (context) => const SizedBox.shrink(),
    );
  }
}

class _SelectionTile extends StatelessWidget {
  final String title;
  final String description;
  final bool selected;
  final Widget image;
  final VoidCallback onTap;

  const _SelectionTile({
    required this.title,
    required this.description,
    required this.selected,
    required this.image,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: selected
          ? colors.selection.fillSelected.withValues(alpha: 0.16)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.s04$xs,
            vertical: AppDimens.s12$md,
          ),
          child: Row(
            children: [
              SizedBox.square(dimension: 64, child: image),
              const SizedBox(width: AppDimens.s08$sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.body16SemiBold(context),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: AppDimens.s04$xs),
                      Text(
                        description,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.caption(context),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
