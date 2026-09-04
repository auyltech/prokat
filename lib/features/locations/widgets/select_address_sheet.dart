import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/features/locations/widgets/location_tile.dart';
import 'package:prokat/features/user/state/client_profile_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

class SelectAddressSheet extends ConsumerWidget {
  final String service;
  final String from;
  final String? equipmentId;

  const SelectAddressSheet({
    super.key,
    required this.service,
    required this.from,
    this.equipmentId,
  });

  static void show(
    BuildContext context, {
    required String service,
    required String from,
    String? equipmentId,
  }) {
    unawaited(
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => SelectAddressSheet(
          service: service,
          from: from,
          equipmentId: equipmentId,
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAddress(
    BuildContext context,
    WidgetRef ref,
    String addressId,
  ) async {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.deleteAddressQuestion),
        content: Text(l10n.deleteAddressConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final deleted = await ref
        .read(locationProvider.notifier)
        .deleteLocation(addressId);

    if (!context.mounted) return;

    if (deleted) {
      await ref.read(clientProfileProvider.notifier).refresh();
      return;
    }

    AppSnackBar.show(message: l10n.failedToDeleteAddress, isError: true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final locationState = ref.watch(locationProvider);
    final addresses = locationState.clientLocations;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

          if (addresses.isNotEmpty)
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.45,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: addresses.length,
                itemBuilder: (context, index) {
                  final address = addresses[index];
                  final addressId = address.id;
                  final isDeleting =
                      addressId != null &&
                      locationState.isActionActive(
                        'location:$addressId:delete',
                      );

                  return LocationTile(
                    location: address,
                    isDeleting: isDeleting,
                    onDelete: addressId == null || isDeleting
                        ? null
                        : () => unawaited(
                            _confirmDeleteAddress(context, ref, addressId),
                          ),
                    onTap: () {
                      ref
                          .read(locationProvider.notifier)
                          .selectAddress(address);

                      if (from == 'profile' && (addressId ?? '').isNotEmpty) {
                        unawaited(
                          ref
                              .read(clientProfileMutationProvider.notifier)
                              .selectAddress(addressId!),
                        );
                      }

                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),

          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                unawaited(
                  context.push(
                    AppRoutes.clientPinAddress,
                    extra: {
                      'equipmentId': equipmentId,
                      "service": service,
                      "from": from,
                    },
                  ),
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
