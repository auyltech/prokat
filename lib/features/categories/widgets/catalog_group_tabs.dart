import 'package:flutter/material.dart';
import 'package:prokat/core/theme/app_dimens.dart';
import 'package:prokat/core/theme/app_fonts.dart';
import 'package:prokat/features/catalog/models/catalog_group.dart';
import 'package:prokat/l10n/app_localizations.dart';

/// Shows Техника / Оборудование tabs only when [groups] has both entries.
///
/// Each segment widths to its label (not equalized like [SegmentedButton]).
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
    final theme = Theme.of(context);
    final value = groups.contains(selected) ? selected : groups.first;
    final borderColor = theme.dividerColor.withValues(alpha: 0.4);
    final borderRadius = BorderRadius.circular(AppDimens.r12$lg);

    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: borderRadius,
          border: Border.all(color: borderColor),
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: IntrinsicHeight(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < groups.length; i++) ...[
                  if (i > 0)
                    VerticalDivider(width: 1, thickness: 1, color: borderColor),
                  _CatalogGroupSegment(
                    label: switch (groups[i]) {
                      CatalogGroup.machinery => l10n.catalogGroupMachinery,
                      CatalogGroup.equipment => l10n.catalogGroupEquipment,
                    },
                    selected: groups[i] == value,
                    onTap: () => onChanged(groups[i]),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CatalogGroupSegment extends StatelessWidget {
  const _CatalogGroupSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inactiveTextColor = theme.dividerColor.withValues(alpha: 0.4);

    final baseStyle = AppFonts.headingS(context);
    final color = selected ? baseStyle.color : inactiveTextColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.s20$lg,
            vertical: AppDimens.s12$md,
          ),
          child: Text(label, style: baseStyle.copyWith(color: color)),
        ),
      ),
    );
  }
}
