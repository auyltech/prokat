import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/features/locations/widgets/location_tile.dart';
import 'package:prokat/l10n/app_localizations.dart';

class SelectAddressSheet extends ConsumerWidget {
  final String service;
  final String? equipmentId;

  const SelectAddressSheet({
    super.key,
    this.equipmentId,
    required this.service,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final locationState = ref.watch(locationProvider);
    final addresses = locationState.clientLocations.take(3).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          Text(
            l10n.selectAddress,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 16),

          /// Recent History List
          if (addresses.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                l10n.noRecentAddresses,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            )
          else
            ...addresses.map(
              (address) => LocationTile(
                location: address,
                onTap: () {
                  ref.read(locationProvider.notifier).selectAddress(address);
                  Navigator.pop(context);
                },
              ),
            ),

          const SizedBox(height: 8),

          /// Choose on Map Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                context.push(
                  AppRoutes.clientPinAddress,
                  extra: {'equipmentId': equipmentId, "service": service},
                );
              },
              icon: const Icon(Icons.map_outlined, size: 24),
              label: Text(
                l10n.chooseOnMap,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                side: BorderSide(
                  color: theme.colorScheme.outline.withAlpha(50),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                backgroundColor: theme.colorScheme.surfaceBright,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
