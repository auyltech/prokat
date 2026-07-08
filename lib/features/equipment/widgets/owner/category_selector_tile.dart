import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/equipment/providers/equipment_mutation_provider.dart';
import 'package:prokat/features/equipment/providers/equipment_provider.dart';
import 'package:prokat/features/equipment/providers/owner_equipment_details_provider.dart';
import 'package:prokat/features/equipment/widgets/owner/category_selection_sheet.dart';
import 'package:prokat/features/requests/providers/request_mutation_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

// Used for creating and editing equipment
class CategorySelectorTile extends ConsumerStatefulWidget {
  final String mode;
  const CategorySelectorTile({super.key, required this.mode});

  @override
  ConsumerState<CategorySelectorTile> createState() =>
      _CategorySelectorTileState();
}

class _CategorySelectorTileState extends ConsumerState<CategorySelectorTile> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final editEquipmentId =
        ref.watch(equipmentMutationProvider).editingEquipmentId ?? "";

    final equipment = ref
        .watch(ownerEquipmentDetailsProvider(editEquipmentId))
        .value;

    final selectedCategory =
        widget.mode == "create_request" || widget.mode == "create_equipment"
        ? ref.watch(requestMutationProvider).selectedCategory
        : ref.watch(equipmentMutationProvider).category;

    final categoryName = selectedCategory?.name ?? l10n.selectService;

    final bool hasCategory = selectedCategory != null;

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
          ref.read(searchEquipmentProvider.notifier).selectCategory(picked);
        }

        return null;
      }

      if (picked?.id != null && equipment?.categoryId != picked?.id) {
        if (widget.mode == "edit_equipment") {
          final res = await ref
              .read(equipmentMutationProvider.notifier)
              .updateEquipmentCategory(
                equipmentId: equipment?.id ?? "",
                categoryId: picked?.id ?? "",
              );

          if (mounted && res == true) {
            ScaffoldMessenger.of(this.context).showSnackBar(
              SnackBar(
                content: Text(l10n.equipmentUpdated),
                backgroundColor: theme.colorScheme.primary,
              ),
            );
          }
        } else if (mounted) {
          ScaffoldMessenger.of(this.context).showSnackBar(
            SnackBar(
              content: Text(l10n.updateFailed),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      }
    }

    return GestureDetector(
      onTap: onCategoryTap,
      child: Row(
        children: [
          // Icon Container
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: hasCategory
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceDim,
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasCategory
                  ? _getCategoryIcon(selectedCategory.name)
                  : Icons.category_outlined,
              color: hasCategory
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.3),
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
                  hasCategory ? categoryName : l10n.selectService,
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
