import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/catalog/models/catalog_group.dart';
import 'package:prokat/l10n/app_localizations.dart';

/// Shows Техника / Оборудование when [groups] has both entries.
class CatalogGroupTabs extends StatelessWidget {
  const CatalogGroupTabs({
    super.key,
    required this.groups,
    required this.selected,
    required this.onChanged,
    this.isExpanded = false,
  });

  final List<CatalogGroup> groups;
  final CatalogGroup selected;
  final ValueChanged<CatalogGroup> onChanged;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    if (groups.length < 2) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final value = groups.contains(selected) ? selected : groups.first;

    return AppSegmentedButton<CatalogGroup>(
      isExpanded: isExpanded,
      value: value,
      segments: [
        for (final group in groups)
          AppSegmentedOption(
            value: group,
            title: switch (group) {
              CatalogGroup.machinery => l10n.catalogGroupMachinery,
              CatalogGroup.equipment => l10n.catalogGroupEquipment,
            },
          ),
      ],
      onChanged: onChanged,
    );
  }
}
