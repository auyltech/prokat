import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/locations/state/location_provider.dart';

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

    final locationState = ref.watch(locationProvider);
    final addresses = locationState.renterLocations.take(3).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
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
              margin: const EdgeInsets.only(bottom: 24),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          Text(
            "SELECT ADDRESS",
            style: theme.textTheme.labelMedium?.copyWith(
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 16),

          /// Recent History List
          if (addresses.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                "No recent addresses",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            )
          else
            ...addresses.map(
              (address) => _AddressHistoryTile(
                address: address,
                onTap: () {
                  ref.read(locationProvider.notifier).selectAddress(address);
                  Navigator.pop(context);
                },
              ),
            ),

          const SizedBox(height: 24),

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
              icon: const Icon(Icons.map_outlined, size: 20),
              label: Text(
                "CHOOSE ON MAP",
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                side: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.05,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressHistoryTile extends StatelessWidget {
  final dynamic address;
  final VoidCallback onTap;

  const _AddressHistoryTile({required this.address, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          Icons.history,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          size: 20,
        ),
        title: Text(
          "${address.street}, ${address.city}",
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            color: theme.colorScheme.onSurface,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          size: 18,
        ),
      ),
    );
  }
}
