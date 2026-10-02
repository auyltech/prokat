import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/app_category_info.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/categories/widgets/catalog_group_image.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';

/// Read-only category of an owner's equipment (category is fixed after create).
class OwnerEquipmentCategoryCard extends ConsumerWidget {
  final Equipment equipment;

  const OwnerEquipmentCategoryCard({super.key, required this.equipment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final catalogCategory = ref
        .watch(catalogProvider)
        .valueOrNull
        ?.categoryById(equipment.categoryId);
    final category = catalogCategory != null
        ? Category.fromCatalog(catalogCategory)
        : equipment.category;
    if (category == null) return const SizedBox.shrink();

    return AppCategoryInfo(
      title: category.localizedName(languageCode),
      description: category.localizedDescription(languageCode),
      imageUrl: category.imageUrl,
      fallbackImage: category.catalogGroup.stdImage,
    );
  }
}
