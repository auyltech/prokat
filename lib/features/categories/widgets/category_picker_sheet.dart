import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/catalog/models/catalog_group.dart';
import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/categories/widgets/catalog_group_image.dart';
import 'package:prokat/l10n/app_localizations.dart';

class CategoryPickerResult {
  final Category? category;
  final bool isAll;

  const CategoryPickerResult._({this.category, required this.isAll});

  const CategoryPickerResult.all() : this._(isAll: true);

  const CategoryPickerResult.category(Category category)
    : this._(category: category, isAll: false);
}

class CategoryPickerSheet {
  CategoryPickerSheet._();

  static Future<CategoryPickerResult?> show(
    BuildContext context, {
    required List<Category> categories,
    required CatalogGroup group,
    String? selectedId,
    bool includeAllOption = true,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final flow = ProkatFlowScope.maybeOf(context);

    return AppBottomSheet.showScrollable<CategoryPickerResult>(
      context,
      title: l10n.selectCategory,
      initialChildSize: 0.4,
      minChildSize: 0.2,
      maxChildSize: 0.85,
      headerBuilder: (_) => const SizedBox.shrink(),
      footerBuilder: (_) => const SizedBox.shrink(),
      scrollableListBuilder: (context, scrollController) {
        final list = _CategoryPickerList(
          categories: categories,
          group: group,
          selectedId: selectedId,
          includeAllOption: includeAllOption,
          scrollController: scrollController,
        );
        // The root navigator's sheet route is outside a screen's flow scope.
        return flow == null
            ? list
            : ProkatFlowScope(palette: flow, child: list);
      },
    );
  }

  static const double imageWidth = 100;
}

class _CategoryPickerList extends StatelessWidget {
  final List<Category> categories;
  final CatalogGroup group;
  final String? selectedId;
  final bool includeAllOption;
  final ScrollController scrollController;

  const _CategoryPickerList({
    required this.categories,
    required this.group,
    required this.selectedId,
    required this.includeAllOption,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    final allDescription = group == CatalogGroup.equipment
        ? l10n.allCategoriesEquipmentDescription
        : l10n.allCategoriesMachineryDescription;
    final allImage = group.stdImage;
    final allOffset = includeAllOption ? 1 : 0;
    final flow = ProkatFlowScope.maybeOf(context);

    if (flow != null) {
      return ListView.separated(
        controller: scrollController,
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.paddingOf(context).bottom,
        ),
        itemCount: categories.length + allOffset,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final isAll = includeAllOption && index == 0;
          final category = isAll ? null : categories[index - allOffset];
          return _FlowCategoryPickerTile(
            title: category?.localizedName(languageCode) ?? l10n.allCategories,
            imageUrl: category?.imageUrl,
            group: group,
            selected: isAll ? selectedId == null : selectedId == category!.id,
            palette: flow,
            onTap: () => Navigator.of(context).pop(
              isAll
                  ? const CategoryPickerResult.all()
                  : CategoryPickerResult.category(category!),
            ),
          );
        },
      );
    }

    return ListView.builder(
      controller: scrollController,
      itemCount: categories.length + allOffset,
      itemBuilder: (context, index) {
        if (includeAllOption && index == 0) {
          return _CategoryPickerTile(
            title: l10n.allCategories,
            description: allDescription,
            selected: selectedId == null,
            image: SizedBox(
              height: CategoryPickerSheet.imageWidth * 3 / 4,
              child: allImage(
                size: CategoryPickerSheet.imageWidth,
                fit: BoxFit.contain,
              ),
            ),
            onTap: () =>
                Navigator.of(context).pop(const CategoryPickerResult.all()),
          );
        }

        final category = categories[index - allOffset];
        return _CategoryPickerTile(
          title: category.localizedName(languageCode),
          description: category.localizedDescription(languageCode),
          selected: selectedId == category.id,
          image: _categoryImage(category),
          onTap: () =>
              Navigator.of(context)
                  .pop(CategoryPickerResult.category(category)),
        );
      },
    );
  }

  Widget _categoryImage(Category category) {
    final url = category.imageUrl;
    if (url != null && url.isNotEmpty) {
      return OptimizedNetworkImage(
        imageUrl: url,
        fit: BoxFit.contain,
        height: CategoryPickerSheet.imageWidth * 3 / 4,
        width: CategoryPickerSheet.imageWidth,
      );
    }
    return const Icon(Icons.image_not_supported, size: 32);
  }
}

class _FlowCategoryPickerTile extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final CatalogGroup group;
  final bool selected;
  final ProkatFlowPalette palette;
  final VoidCallback onTap;

  const _FlowCategoryPickerTile({
    required this.title,
    required this.imageUrl,
    required this.group,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: selected ? palette.primarySoft : palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: selected ? palette.primary : palette.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: ColoredBox(
                        color: palette.background,
                        child: imageUrl != null && imageUrl!.isNotEmpty
                            ? OptimizedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.contain,
                                backgroundColor: palette.background,
                              )
                            : group.stdImage(size: 72, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: AppFonts.headingS(context).copyWith(
                      color: palette.title,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox.square(
                  dimension: 20,
                  child: selected
                      ? Icon(
                          LucideIcons.check,
                          size: 20,
                          color: palette.primary,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryPickerTile extends StatelessWidget {
  final String title;
  final String description;
  final bool selected;
  final Widget image;
  final VoidCallback onTap;

  const _CategoryPickerTile({
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
            horizontal: AppDimens.s08$sm,
            vertical: AppDimens.s04$xs,
          ),
          child: Row(
            children: [
              image,
              const SizedBox(width: AppDimens.s12$md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.headingS(context),
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
