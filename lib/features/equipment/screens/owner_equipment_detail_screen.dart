import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/features/equipment/providers/owner_equipment_details_provider.dart';
import 'package:prokat/features/equipment/widgets/owner/category_selection_sheet.dart';
import 'package:prokat/features/equipment/widgets/owner/category_selector_tile.dart';
import 'package:prokat/features/equipment/widgets/owner/delete_equipment_section.dart';
import 'package:prokat/features/equipment/widgets/owner/edit_equipment_details_form.dart';
import 'package:prokat/features/equipment/widgets/owner/owner_equipment_image_header.dart';
import 'package:prokat/features/equipment/widgets/owner/owner_equipment_specs.dart';
import 'package:prokat/features/equipment/widgets/owner/location_section.dart';
import 'package:prokat/features/locations/location_label.dart';
import 'package:prokat/features/equipment/widgets/owner/pricing_section.dart';
import 'package:prokat/features/equipment/widgets/owner/visibility_status_section.dart';
import 'package:prokat/l10n/app_localizations.dart';

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
      await ref.read(ownerEquipmentDetailsProvider(widget.equipmentId).future);

      await ref.read(categoriesProvider.notifier).refreshIfStale();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final equipmentAsync = ref.watch(
      ownerEquipmentDetailsProvider(widget.equipmentId),
    );

    final bool isErrorState = equipmentAsync.hasError;

    return Scaffold(
      backgroundColor: isErrorState
          ? theme.colorScheme.errorContainer
          : theme.colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(ownerEquipmentDetailsProvider(widget.equipmentId));
        },
        child: equipmentAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),

          error: (_, _) => EmptyStateTile(
            title: l10n.systemError,
            imageName: 'empty_error.png',
            subtitle: l10n.equipmentDataNotLocated,
          ),

          data: (equipment) => ListView(
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
                    CategorySelectorTile(
                      mode: CategorySheetMode.editEquipment,
                      selectedCategoryId: equipmentAsync.value?.categoryId,
                    ),

                    const SizedBox(height: 20),

                    EditEquipmentDetailsForm(equipment: equipment, ref: ref),

                    OwnerEquipmentSpecs(equipment: equipment),

                    const SizedBox(height: 20),

                    PricingSection(
                      prices: equipment.prices,
                      equipmentId: equipment.id,
                      isDraft: equipment.isDraft,
                    ),

                    LocationSection(
                      ref: ref,
                      equipment: equipment,
                      location: equipment.location != null
                          ? formatEquipmentLocation(
                              ref,
                              context,
                              equipment.location!,
                            )
                          : "",
                    ),

                    const SizedBox(height: 20),

                    VisibilityStatusSection(equipment: equipment),

                    const SizedBox(height: 20),

                    DeleteEquipmentSection(equipmentId: equipment.id),
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
