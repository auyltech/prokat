import 'package:flutter/material.dart';
import 'package:prokat/core/constants/app_colors.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/features/billing/models/volume_discount_model.dart';
import 'package:prokat/l10n/app_localizations.dart';

class VolumeDiscountTile extends StatelessWidget {
  final VolumeDiscountModel volumeCase;
  final bool isHighlighted;

  const VolumeDiscountTile({
    super.key,
    required this.volumeCase,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isHighlighted
            ? colorScheme.primaryContainer.withValues(alpha: 0.15)
            : theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted
              ? AppColors.teal700
              : theme.dividerColor.withValues(alpha: 0.2),
          width: isHighlighted ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.equipmentCountLabel(volumeCase.onlineCount),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          if (isHighlighted) ...[
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: AppColors.teal700,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  l10n.bestValue,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isHighlighted
                  ? AppColors.teal700
                  : colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              l10n.minutesPerHourValue(
                formatPriceNumber(volumeCase.costPerMinute),
              ),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isHighlighted ? Colors.white : colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
