import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/features/equipment/state/equipment_provider.dart';
import 'package:prokat/features/equipment/widgets/owner/category_selector_tile.dart';
import 'package:prokat/features/equipment/widgets/owner/delete_equipment_section.dart';
import 'package:prokat/features/equipment/widgets/owner/edit_equipment_details_form.dart';
import 'package:prokat/features/equipment/widgets/owner/owner_equipment_image_header.dart';
import 'package:prokat/features/equipment/widgets/owner/owner_equipment_specs.dart';
import 'package:prokat/features/equipment/widgets/owner/location_section.dart';
import 'package:prokat/features/equipment/widgets/owner/open_pricing_edit_sheet.dart';
import 'package:prokat/features/equipment/widgets/owner/pricing_section.dart';
import 'package:prokat/features/equipment/widgets/owner/visibility_status_section.dart';

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
      await ref.read(categoriesProvider.notifier).getCategories();

      await ref
          .read(equipmentProvider.notifier)
          .getOwnerEquipmentById(widget.equipmentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(equipmentProvider);

    final equipment = state.editEquipment;

    /// ERROR STATE
    // if (equipment == null) {
    //   return Scaffold(
    //     backgroundColor: bgColor,
    //     body: Center(
    //       child: Column(
    //         mainAxisSize: MainAxisSize.min,
    //         children: [
    //           Icon(
    //             Icons.error_outline,
    //             color: colorScheme.tertiary, // softer warning vs hard orange
    //             size: 48,
    //           ),
    //           const SizedBox(height: 16),
    //           Text(
    //             "SYSTEM ERROR",
    //             style: theme.textTheme.labelMedium?.copyWith(
    //               color: ghostGray,
    //               fontWeight: FontWeight.bold,
    //               letterSpacing: 2,
    //             ),
    //           ),
    //           Text(
    //             "EQUIPMENT DATA NOT LOCATED",
    //             style: theme.textTheme.titleMedium?.copyWith(
    //               color: colorScheme.onSurface,
    //             ),
    //           ),
    //           TextButton(
    //             onPressed: () => context.pop(),
    //             child: Text(
    //               "BACK TO FLEET",
    //               style: TextStyle(color: accentColor),
    //             ),
    //           ),
    //         ],
    //       ),
    //     ),
    //   );
    // }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          ListView(
            children: [
              OwnerEquipmentImageHeader(
                equipmentId: equipment?.id ?? "",
                images: equipment?.images ?? [],
                legacyImageUrl: equipment?.imageUrl ?? " ",
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                child: Column(
                  children: [
                    // Category
                    if (equipment != null)
                      CategorySelectorTile(mode: "edit_equipment"),

                    const SizedBox(height: 20),

                    // Informaton, Name, Model, Plate, rent condition
                    if (equipment != null)
                      EditEquipmentDetailsForm(equipment: equipment, ref: ref),

                    // const SizedBox(height: 20),

                    // Specs, Equipment Technical Info / Tank Capacity / Lift Capacity
                    if (equipment != null)
                      OwnerEquipmentSpecs(equipment: equipment),

                    const SizedBox(height: 20),

                    if (equipment != null)
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
                      ),

                    if (equipment != null)
                      LocationSection(
                        ref: ref,
                        equipment: equipment,
                        location: equipment.location != null
                            ? '${equipment.location?.street}, ${equipment.location?.city}'
                            : "",
                      ),

                    const SizedBox(height: 20),

                    if (equipment != null)
                      VisibilityStatusSection(
                        equipmentId: equipment.id,
                        isVisible: equipment.isVisible,
                        status: equipment.status,
                      ),

                    const SizedBox(height: 20),

                    if (equipment != null)
                      DeleteEquipmentSection(equipmentId: equipment.id),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
