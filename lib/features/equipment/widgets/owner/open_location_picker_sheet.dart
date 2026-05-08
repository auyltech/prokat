import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/equipment/providers/equipment_provider.dart';
import 'package:prokat/features/locations/state/location_provider.dart';

void openLocationPickerSheet(
  BuildContext context,
  WidgetRef ref,
  String equipmentId,
) {
  final theme = Theme.of(context);
  final bgColor = theme.colorScheme.surface;
  final accentColor = theme.colorScheme.primary;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      final locations = ref.watch(locationProvider).ownerLocations;
      final topLocations = locations.take(5).toList();

      return Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: Color(0x14FFFFFF), width: 1)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, // Move header to left
          children: [
            Align(
              alignment: Alignment.center,
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              "Select Location",
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 16),

            //  Display Top 3 Locations
            if (topLocations.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  "No saved locations yet",
                  style: TextStyle(color: Colors.black, fontSize: 13),
                ),
              )
            else
              ...topLocations.map(
                (loc) => _LocationTile(
                  icon: Icons.location_on_outlined,
                  title: loc.street,
                  subtitle: loc.city,
                  onTap: () async {
                    // Update your notifier with the selection
                    final res = await ref
                        .read(equipmentProvider.notifier)
                        .updateEquipmentLocation(equipmentId, {
                          "id": equipmentId,
                          "locationId": loc.id,
                        });

                    if (res == true) {
                      Navigator.pop(context);
                    }
                  },
                ),
              ),

            const SizedBox(height: 8),

            // "Add New" Button
            InkWell(
              onTap: () {
                context.pop();

                context.push(AppRoutes.ownerAddressMap);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.add_location_alt_rounded,
                      color: accentColor,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Create new on map",
                      style: theme.textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      );
    },
  );
}

class _LocationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _LocationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor, // Recessed panel
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.4),
            ),
          ),

          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.bodyLarge),

                    const SizedBox(height: 2),

                    Text(subtitle, style: theme.textTheme.labelLarge),
                  ],
                ),
              ),

              Icon(
                Icons.arrow_forward_ios_rounded,
                color: theme.colorScheme.onSurface,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
