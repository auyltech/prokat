import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/features/categories/providers/category_provider.dart';
import 'package:prokat/features/equipment/providers/equipment_provider.dart';
import 'package:prokat/features/equipment/widgets/owner/category_selector_tile.dart';
import 'package:prokat/features/equipment/widgets/owner/delete_equipment_section.dart';
import 'package:prokat/features/equipment/widgets/owner/edit_equipment_details_form.dart';
import 'package:prokat/features/equipment/widgets/owner/owner_equipment_image_header.dart';
import 'package:prokat/features/equipment/widgets/owner/location_section.dart';
import 'package:prokat/features/equipment/widgets/owner/open_location_picker_sheet.dart';
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bgColor = colorScheme.surface;
    final ghostGray = colorScheme.onSurface.withValues(alpha: 0.6);
    final accentColor = colorScheme.primary;

    final state = ref.watch(equipmentProvider);

    final equipment = state.ownerEquipment
        .where((item) => item.id == widget.equipmentId)
        .firstOrNull;

    /// ERROR STATE
    if (equipment == null) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: colorScheme.tertiary, // softer warning vs hard orange
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                "SYSTEM ERROR",
                style: theme.textTheme.labelMedium?.copyWith(
                  color: ghostGray,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              Text(
                "EQUIPMENT DATA NOT LOCATED",
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: () => context.pop(),
                child: Text(
                  "BACK TO FLEET",
                  style: TextStyle(color: accentColor),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: OwnerEquipmentImageHeader(
                  equipmentId: equipment.id,
                  images: equipment.images,
                  legacyImageUrl: equipment.imageUrl,
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    CategorySelectorTile(mode: "edit_equipment"),

                    const SizedBox(height: 20),

                    EditEquipmentDetailsForm(equipment: equipment, ref: ref),

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
                    ),

                    const SizedBox(height: 20),

                    LocationSection(
                      ref: ref,
                      equipment: equipment,
                      location: equipment.location != null
                          ? '${equipment.location?.street}, ${equipment.location?.city}'
                          : "NO LOCATION SET",
                      onAction: () =>
                          openLocationPickerSheet(context, ref, equipment.id),
                    ),

                    const SizedBox(height: 20),

                    VisibilityStatusSection(
                      isVisible: equipment.isVisible,
                      status: equipment.status,
                      onSave: (visible, status) {
                        ref
                            .read(equipmentProvider.notifier)
                            .updateVisibilityStatus(
                              equipment.id,
                              visible,
                              status,
                            );
                      },
                    ),

                    const SizedBox(height: 20),

                    DeleteEquipmentSection(
                      onDelete: () =>
                          _confirmDelete(context, ref, widget.equipmentId),
                    ),
                  ]),
                ),
              ),
            ],
          ),

          Positioned(
            top:
                MediaQuery.of(context).padding.top +
                12, // Respects notch/status bar
            left: 16,
            child: GestureDetector(
              onTap: () => context.pop(), // GoRouter back action
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3), // Low alpha shade
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String equipmentId) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          12,
          24,
          MediaQuery.of(context).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// DRAG HANDLE
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 32),

            /// ICON
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_sweep_rounded,
                color: colorScheme.error,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),

            /// TITLE
            Text(
              "Delete Equipment?",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            /// DESCRIPTION
            Text(
              "This will remove the item from the marketplace and delete all its rental history.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),

            const SizedBox(height: 32),

            /// DELETE BUTTON
            SizedBox(
              width: double.infinity,
              height: 60,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () async {
                  await ref
                      .read(equipmentProvider.notifier)
                      .deleteEquipment(equipmentId);

                  if (context.mounted && context.canPop()) context.pop();

                  if (context.mounted) {
                    context.pop();
                  }
                },
                child: const Text(
                  "Yes, Delete Permanently",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 12),

            /// CANCEL
            TextButton(
              onPressed: () => context.pop(),
              child: Text(
                "Keep it for now",
                style: TextStyle(color: colorScheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
