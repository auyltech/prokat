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
  static Future<CategoryPickerResult?> show(
    BuildContext context, {
    required List<Category> categories,
    required CatalogGroup group,
    String? selectedId,
  }) {
    final l10n = AppLocalizations.of(context)!;

    return AppBottomSheet.show<CategoryPickerResult>(
      context,
      title: l10n.selectCategory,
      contentBuilder: (context) {
        return _CategoryPickerList(
          categories: categories,
          group: group,
          selectedId: selectedId,
        );
      },
    );
  }
}

class _CategoryPickerList extends StatelessWidget {
  final List<Category> categories;
  final CatalogGroup group;
  final String? selectedId;

  const _CategoryPickerList({
    required this.categories,
    required this.group,
    required this.selectedId,
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

    return ListView(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      children: [
        _CategoryPickerTile(
          title: l10n.allCategories,
          description: allDescription,
          selected: selectedId == null,
          image: allImage(size: 48, fit: BoxFit.cover),
          onTap: () =>
              Navigator.of(context).pop(const CategoryPickerResult.all()),
        ),
        for (final category in categories)
          _CategoryPickerTile(
            title: category.localizedName(languageCode),
            description: category.localizedDescription(languageCode),
            selected: selectedId == category.id,
            image: _categoryImage(category),
            onTap: () =>
                Navigator.of(context)
                    .pop(CategoryPickerResult.category(category)),
          ),
      ],
    );
  }

  Widget _categoryImage(Category category) {
    final url = category.imageUrl;
    if (url != null && url.isNotEmpty) {
      return OptimizedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        height: 48,
        width: 48,
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
            horizontal: AppDimens.s04$xs,
            vertical: AppDimens.s12$md,
          ),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 48,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimens.r08$md),
                  child: image,
                ),
              ),
              const SizedBox(width: AppDimens.s12$md),
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
                        maxLines: 2,
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
