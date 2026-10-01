import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/catalog/models/catalog_group.dart';
import 'package:prokat/features/equipment/providers/owner_equipment_details_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

/// App bar title of the owner equipment detail screen; depends on the group.
class OwnerEquipmentDetailTitle extends ConsumerWidget {
  final String equipmentId;

  const OwnerEquipmentDetailTitle({super.key, required this.equipmentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final group = ref.watch(ownerEquipmentCatalogGroupProvider(equipmentId));

    return Text(switch (group) {
      null => '',
      CatalogGroup.machinery => l10n.machineryDetailsTitle,
      CatalogGroup.equipment => l10n.equipmentCatalogDetailsTitle,
    });
  }
}
