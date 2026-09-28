import 'package:flutter/material.dart';
import 'package:prokat/features/catalog/models/catalog_group.dart';
import 'package:prokat/l10n/app_localizations.dart';

/// Shows Техника / Оборудование tabs only when [groups] has both entries.
class CatalogGroupTabs extends StatelessWidget {
  const CatalogGroupTabs({
    super.key,
    required this.groups,
    required this.selected,
    required this.onChanged,
  });

  final List<CatalogGroup> groups;
  final CatalogGroup selected;
  final ValueChanged<CatalogGroup> onChanged;

  @override
  Widget build(BuildContext context) {
    if (groups.length < 2) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final value = groups.contains(selected) ? selected : groups.first;

    return SegmentedButton<CatalogGroup>(
      segments: [
        for (final group in groups)
          ButtonSegment(
            value: group,
            label: Text(switch (group) {
              CatalogGroup.machinery => l10n.catalogGroupMachinery,
              CatalogGroup.equipment => l10n.catalogGroupEquipment,
            }),
          ),
      ],
      selected: {value},
      onSelectionChanged: (next) {
        if (next.isEmpty) return;
        onChanged(next.first);
      },
    );
  }
}
