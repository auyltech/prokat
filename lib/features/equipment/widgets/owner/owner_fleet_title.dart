import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/catalog/models/catalog_group.dart';
import 'package:prokat/features/equipment/providers/owner_equipment_provider.dart';
import 'package:prokat/features/equipment/providers/owner_fleet_groups_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

/// Title of the owner's own listings. Both groups share «Мой парк»; one group
/// is named directly and has no tab bar.
class OwnerFleetTitle extends ConsumerWidget {
  const OwnerFleetTitle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final items =
        ref.watch(ownerEquipmentProvider).valueOrNull?.items ?? const [];
    final fetched = ref.watch(ownerFleetGroupsProvider).valueOrNull;
    if (fetched == null && items.isEmpty) return const SizedBox.shrink();

    final fleet = resolveOwnerFleetGroups(fetched: fetched, items: items);
    if (fleet.length > 1) return Text(l10n.ownerFleet);

    final group = fleet.isEmpty ? CatalogGroup.machinery : fleet.single;
    return Text(switch (group) {
      CatalogGroup.machinery => l10n.myEquipment,
      CatalogGroup.equipment => l10n.ownerFleetEquipment,
    });
  }
}
