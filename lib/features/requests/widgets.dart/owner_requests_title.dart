import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/catalog/models/catalog_group.dart';
import 'package:prokat/features/equipment/providers/owner_fleet_groups_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

/// App bar title for the owner request inbox. Depends on which groups the
/// owner actually has in the fleet.
class OwnerRequestsTitle extends ConsumerWidget {
  const OwnerRequestsTitle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final groups = ref.watch(ownerFleetGroupsProvider).valueOrNull;
    if (groups == null) return const SizedBox.shrink();
    if (groups.length > 1) return Text(l10n.rentalRequests);

    final group = groups.isEmpty ? CatalogGroup.machinery : groups.single;
    return Text(switch (group) {
      CatalogGroup.machinery => l10n.rentalRequestsMachinery,
      CatalogGroup.equipment => l10n.rentalRequestsEquipment,
    });
  }
}
