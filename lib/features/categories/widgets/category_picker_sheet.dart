import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/catalog/models/catalog_group.dart';
import 'package:prokat/features/categories/models/category.dart';
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
  }) {
    final l10n = AppLocalizations.of(context)!;

    return AppBottomSheet.showScrollable<CategoryPickerResult>(
      context,
      title: l10n.selectCategory,
      initialChildSize: 0.4,
      minChildSize: 0.2,
      maxChildSize: 0.85,
      headerBuilder: (_) => const SizedBox.shrink(),
      footerBuilder: (_) => const SizedBox.shrink(),
      scrollableListBuilder: (context, scrollController) {
        return _CategoryPickerList(
          categories: categories,
          group: group,
          selectedId: selectedId,
          scrollController: scrollController,
        );
      },
    );
  }

  static const double imageWidth = 100;
}

class _CategoryPickerList extends StatelessWidget {
  final List<Category> categories;
  final CatalogGroup group;
  final String? selectedId;
  final ScrollController scrollController;

  const _CategoryPickerList({
    required this.categories,
    required this.group,
    required this.selectedId,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    final allDescription = group == CatalogGroup.equipment
        ? l10n.allCategoriesEquipmentDescription
        : l10n.allCategoriesMachineryDescription;
    final allImage = group == CatalogGroup.equipment
        ? AppImages.equipmentStd
        : AppImages.machineryStd;

    return ListView.builder(
      controller: scrollController,
      itemCount: categories.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
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

        final category = categories[index - 1];
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
