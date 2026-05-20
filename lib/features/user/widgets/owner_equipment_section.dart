import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/features/equipment/providers/equipment_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

class OwnerEquipmentSection extends ConsumerStatefulWidget {
  const OwnerEquipmentSection({super.key});

  @override
  ConsumerState<OwnerEquipmentSection> createState() =>
      _OwnerEquipmentSectionState();
}

class _OwnerEquipmentSectionState extends ConsumerState<OwnerEquipmentSection> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final equipment = ref.watch(equipmentProvider).ownerEquipment;

    final equipmentCount = equipment.length;
    final hasEquipment = equipmentCount > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.train_outlined,
                color: colorScheme.primary,
                size: 30,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.myFleet,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    hasEquipment
                        ? '${equipmentCount.toString().padLeft(2, '0')} ${equipmentCount == 1 ? l10n.equipmentItemSingular : l10n.equipmentItemsPlural}'
                        : l10n.noItemsTapToAdd,
                    style: theme.textTheme.labelMedium,
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => context.push(AppRoutes.ownerEquiment),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                visualDensity: VisualDensity.compact,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.viewAll,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios, size: 12),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        if (equipment.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(l10n.noEquipmentFound),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 0),
            itemCount: equipment.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = equipment[index];
              final isOnline = item.isVisible;

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: OptimizedNetworkImage(
                        imageUrl: item.imageUrl ?? "",
                        width: 90,
                        height: 60,
                        fit: BoxFit.cover,
                        fallbackIcon: Icons.image,
                        backgroundColor: colorScheme.surface,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          context.push("${AppRoutes.ownerEquiment}/${item.id}");
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              item.plateNumber ?? "",
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (item.status == "AVAILABLE" || item.status == "ACCEPTED")
                      Column(
                        children: [
                          Switch.adaptive(
                            value: isOnline,
                            onChanged: (val) async {
                              await ref
                                  .read(equipmentProvider.notifier)
                                  .updateVisibilityStatus(
                                    item.id,
                                    val,
                                    "AVAILABLE",
                                  );
                            },
                            activeThumbColor: Colors.green,
                          ),
                          Text(
                            isOnline ? l10n.onlineStatus : l10n.offlineStatus,
                            style: TextStyle(
                              fontSize: 10,
                              color: isOnline
                                  ? Colors.green
                                  : colorScheme.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
