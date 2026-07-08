import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/features/equipment/models/price_entry_model.dart';
import 'package:prokat/features/equipment/providers/equipment_mutation_provider.dart';
import 'package:prokat/features/equipment/providers/owner_equipment_details_provider.dart';
import 'package:prokat/features/equipment/widgets/owner/category_selector_tile.dart';
import 'package:prokat/features/equipment/widgets/owner/delete_equipment_section.dart';
import 'package:prokat/features/equipment/widgets/owner/edit_equipment_details_form.dart';
import 'package:prokat/features/equipment/widgets/owner/owner_equipment_image_header.dart';
import 'package:prokat/features/equipment/widgets/owner/owner_equipment_specs.dart';
import 'package:prokat/features/equipment/widgets/owner/location_section.dart';
import 'package:prokat/features/equipment/widgets/owner/open_pricing_edit_sheet.dart';
import 'package:prokat/features/equipment/widgets/owner/pricing_section.dart';
import 'package:prokat/features/equipment/widgets/owner/visibility_status_section.dart';
import 'package:go_router/go_router.dart';

class OwnerEquipmentDetailScreen extends ConsumerStatefulWidget {
  final String equipmentId;

  const OwnerEquipmentDetailScreen({super.key, required this.equipmentId});

  @override
  ConsumerState<OwnerEquipmentDetailScreen> createState() =>
      _OwnerEquipmentDetailScreenState();
}

class _OwnerEquipmentDetailScreenState
    extends ConsumerState<OwnerEquipmentDetailScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      await Future.wait([
        ref.read(categoriesProvider.notifier).getCategories(),
        ref.read(ownerEquipmentDetailsProvider(widget.equipmentId).future),
      ]);
    });
  }

  Future<void> handleDelete(PriceEntry entry, String equipmentId) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must tap a button to dismiss
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Price Entry'),
          content: Text('Are you sure you want to delete this price entry?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final bool result = await ref
        .read(equipmentMutationProvider.notifier)
        .deletePriceEntry(entry, equipmentId);

    AppSnackBar.show(
      message: result ? "Price entry deleted" : "Failed to delete price entry",
      isSuccess: result,
      isError: !result,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final equipmentAsync = ref.watch(
      ownerEquipmentDetailsProvider(widget.equipmentId),
    );

    return equipmentAsync.when(
      loading: () => Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      ),

      error: (_, __) => Scaffold(
        backgroundColor: theme.colorScheme.errorContainer,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: theme.colorScheme.tertiary,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                "SYSTEM ERROR",
                style: theme.textTheme.labelMedium?.copyWith(
                  color: Colors.grey[200],
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              Text(
                "EQUIPMENT DATA NOT LOCATED",
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.pop(),
                child: Text(
                  "BACK TO FLEET",
                  style: TextStyle(color: theme.primaryColor),
                ),
              ),
            ],
          ),
        ),
      ),

      data: (equipment) {
        return Scaffold(
          backgroundColor: theme.colorScheme.surface,
          body: ListView(
            children: [
              OwnerEquipmentImageHeader(
                equipmentId: equipment.id,
                images: equipment.images,
                legacyImageUrl: equipment.imageUrl ?? "",
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                child: Column(
                  children: [
                    CategorySelectorTile(mode: "edit_equipment"),

                    const SizedBox(height: 20),

                    EditEquipmentDetailsForm(equipment: equipment, ref: ref),

                    OwnerEquipmentSpecs(equipment: equipment),

                    const SizedBox(height: 20),

                    PricingSection(
                      prices: equipment.prices,
                      onAdd: () =>
                          openPricingEditSheet(context, ref, equipment.id),
                      onEdit: (entry) => openPricingEditSheet(
                        context,
                        ref,
                        equipment.id,
                        priceEntry: entry,
                      ),
                      onDelete: (entry) => handleDelete(entry, equipment.id),
                    ),

                    LocationSection(
                      ref: ref,
                      equipment: equipment,
                      location: equipment.location != null
                          ? '${equipment.location!.street}, ${equipment.location!.city}'
                          : "",
                    ),

                    const SizedBox(height: 20),

                    VisibilityStatusSection(
                      equipmentId: equipment.id,
                      isVisible: equipment.isVisible,
                      status: equipment.status,
                    ),

                    const SizedBox(height: 20),

                    DeleteEquipmentSection(equipmentId: equipment.id),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
