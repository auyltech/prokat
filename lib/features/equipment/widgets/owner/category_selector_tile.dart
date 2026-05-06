import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/categories/providers/category_provider.dart';
import 'package:prokat/features/equipment/providers/equipment_provider.dart';
import 'package:prokat/features/equipment/widgets/owner/category_selection_sheet.dart';

class CategorySelectorTile extends ConsumerStatefulWidget {
  final String mode;
  const CategorySelectorTile({super.key, required this.mode});

  @override
  ConsumerState<CategorySelectorTile> createState() =>
      _OwnerEquipmentDetailScreenState();
}

class _OwnerEquipmentDetailScreenState
    extends ConsumerState<CategorySelectorTile> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final equipmentNotifier = ref.watch(equipmentProvider);
    final equipment = equipmentNotifier.ownerEquipment
        .where((item) => item.id == equipmentNotifier.editEquipment?.id)
        .firstOrNull;

    final categories = ref.read(categoriesProvider).categories;

    final isSelected = equipment?.categoryId != null;
    final selectedCategory =
        widget.mode == "create_request" || widget.mode == "create_equipment"
        ? equipmentNotifier.category
        : categories
              .where((cat) => cat.id == equipment?.categoryId)
              .firstOrNull;

    final categoryName = selectedCategory?.name ?? "Select Service";
    final bool hasCategory =
        widget.mode == "create_request" || widget.mode == "create_equipment"
        ? selectedCategory != null
        : equipment?.categoryId != null && selectedCategory != null;

    void onCategoryTap() async {
      final Category? picked = await showModalBottomSheet<Category>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => CategorySelectionSheet(service: widget.mode),
      );

      if (widget.mode == "create_equipment" ||
          widget.mode == "create_request") {
        if (picked != null) {
          ref.read(equipmentProvider.notifier).selectCategory(picked);
        }

        return null;
      }

      if (picked?.id != null && equipment?.categoryId != picked?.id) {
        if (widget.mode == "edit_equipment") {
          final res = await ref
              .read(equipmentProvider.notifier)
              .updateEquipmentCategory(
                equipmentId: equipment?.id ?? "",
                categoryId: picked?.id ?? "",
              );

          if (mounted && res == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text("Equipment Updated"),
                backgroundColor: theme.colorScheme.primary,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Update Failed"),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      }
    }

    return GestureDetector(
      onTap: onCategoryTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.4),
          ),
          // boxShadow: [
          //   BoxShadow(
          //     color: Colors.black.withValues(alpha: 0.3),
          //     blurRadius: 8,
          //     offset: const Offset(0, 4),
          //   ),
          // ],
        ),
        child: Row(
          children: [
            // Icon Container
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary.withValues(alpha: 0.6)
                    : theme.colorScheme.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasCategory
                    ? _getCategoryIcon(selectedCategory.name)
                    : Icons.category_outlined,
                color: hasCategory
                    ? theme.colorScheme.primary
                    : theme.colorScheme.secondary.withValues(alpha: 0.3),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text("Service", style: theme.textTheme.labelLarge),
                  // const SizedBox(height: 2),
                  Text(
                    hasCategory ? categoryName : "Select Service",
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            // Trailing arrow
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('septic')) return Icons.local_shipping_rounded;
    if (n.contains('truck')) return Icons.fire_truck_rounded;
    if (n.contains('excavator')) return Icons.precision_manufacturing_rounded;
    return Icons.construction_rounded;
  }
}
