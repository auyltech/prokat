import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/features/equipment/providers/equipment_provider.dart';
import 'package:prokat/features/equipment/widgets/owner/category_selection_sheet.dart';
import 'package:prokat/l10n/app_localizations.dart';

// Used for creating and editing equipment
class CategorySelectorTile extends ConsumerStatefulWidget {
  final CategorySheetMode mode;
  final String? selectedCategoryId;
  final String? errorText;
  final ValueChanged<Category?>? onChanged;

  const CategorySelectorTile({
    super.key,
    required this.mode,
    this.selectedCategoryId,
    this.errorText,
    this.onChanged,
  });

  @override
  ConsumerState<CategorySelectorTile> createState() =>
      _CategorySelectorTileState();
}

class _CategorySelectorTileState extends ConsumerState<CategorySelectorTile> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // final editEquipmentId = ref
    //     .watch(equipmentMutationProvider)
    //     .editingEquipmentId;

    // final equipment = (editEquipmentId != null && editEquipmentId.isNotEmpty)
    //     ? ref.watch(ownerEquipmentDetailsProvider(editEquipmentId)).valueOrNull
    //     : null;

    final categories =
        ref.watch(categoriesProvider).valueOrNull?.items ?? const [];
    final selectedCategory = categories
        .where((item) => item.id == widget.selectedCategoryId)
        .firstOrNull;

    // widget.mode == CategorySheetMode.createRequest ||
    //     widget.mode == CategorySheetMode.createEquipment
    // ? ref.watch(requestMutationProvider).selectedCategory
    // : ref.watch(equipmentMutationProvider).category;

    final categoryName =
        selectedCategory?.localizedName(
          Localizations.localeOf(context).languageCode,
        ) ??
        l10n.selectService;
    final bool hasCategory = selectedCategory != null;
    final hasError = (widget.errorText ?? '').isNotEmpty;
    final errorColor = theme.colorScheme.error;

    void onCategoryTap() async {
      final Category? picked = await CategorySelectionSheet.show(
        context,
        service: widget.mode,
      );

      if (picked != null) {
        if (!mounted) return;
        widget.onChanged?.call(picked);
      }

      if (widget.mode == CategorySheetMode.createEquipment ||
          widget.mode == CategorySheetMode.createRequest) {
        if (picked != null) {
          ref.read(searchEquipmentProvider.notifier).selectCategory(picked);
        }

        return null;
      }

      if (widget.mode == CategorySheetMode.editEquipment) {
        return null;

        // picked?.id != null &&
        //     equipment?.categoryId != picked?.id &&
        // final result = await ref
        //     .read(equipmentMutationProvider.notifier)
        //     .updateEquipmentCategory(
        //       equipmentId: equipment?.id ?? "",
        //       categoryId: picked?.id ?? "",
        //     );

        // AppSnackBar.show(
        //   message: result ? l10n.equipmentUpdated : l10n.updateFailed,
        //   isSuccess: result,
        //   isError: !result,
        // );
      }
    }

    return GestureDetector(
      onTap: widget.mode == CategorySheetMode.editEquipment
          ? null
          : onCategoryTap,
      child: Row(
        children: [
          // Icon Container
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: hasError
                  ? errorColor.withValues(alpha: 0.2)
                  : hasCategory
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceDim,
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasCategory
                  ? _getCategoryIcon(selectedCategory.name)
                  : Icons.category_outlined,
              color: hasError
                  ? errorColor
                  : hasCategory
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.3),
              size: 24,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.service,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: hasError ? errorColor : null,
                  ),
                ),
                Text(
                  hasCategory ? categoryName : l10n.selectService,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: hasError ? errorColor : null,
                  ),
                ),
                if (hasError) ...[
                  const SizedBox(height: 6),
                  Text(
                    widget.errorText!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: errorColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Trailing arrow
          if (widget.mode != CategorySheetMode.editEquipment)
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.outline.withValues(alpha: 0.6),
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
