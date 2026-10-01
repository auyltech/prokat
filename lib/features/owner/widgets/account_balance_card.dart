import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/core/widgets/base_tile.dart';
import 'package:prokat/l10n/app_localizations.dart';

class AccountBalanceCard extends StatelessWidget {
  final int minutesRemaining;
  final bool online;
  final int equipmentCount;
  final double burnRate;
  final bool billingActive;
  final String? exhaustionLabel;
  final String? title;
  final String? zeroBalanceText;
  final VoidCallback onTopUp;
  final VoidCallback? onHistory;
  const AccountBalanceCard({
    super.key,
    required this.minutesRemaining,
    required this.online,
    required this.equipmentCount,
    required this.burnRate,
    required this.billingActive,
    required this.onTopUp,
    this.onHistory,
    this.exhaustionLabel,
    this.title,
    this.zeroBalanceText,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return BaseTile(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row 1: label + active badge ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title ?? l10n.accountBalance,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (online && equipmentCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1F5EE),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    l10n.equipmentOnlineCount(equipmentCount),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF0D5F5C),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 6),

          // ── Row 2: balance number + action buttons ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                minutesRemaining.toString(),
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                  fontSize: 36,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  l10n.minutesUnit,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ),
              const Spacer(),
              if (onHistory != null) ...[
                _ActionButton(
                  icon: Icons.history_rounded,
                  filled: false,
                  onTap: onHistory ?? () {},
                ),
                const SizedBox(width: 8),
              ],
              _ActionButton(
                icon: Icons.add_rounded,
                filled: true,
                onTap: onTopUp,
              ),
            ],
          ),

          const SizedBox(height: 14),

          Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.5)),

          const SizedBox(height: 12),

          if (minutesRemaining <= 0)
            Text(
              zeroBalanceText ?? l10n.zeroBalanceHiddenFromSearch,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            )
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _FooterMetric(
                  label: l10n.burnRate,
                  value: l10n.burnRateValue(burnRate.round()),
                  align: CrossAxisAlignment.start,
                  valueColor: theme.colorScheme.onSurface,
                ),
                _FooterMetric(
                  label: l10n.estimatedExhaustion,
                  value: billingActive
                      ? (exhaustionLabel ?? l10n.noActiveDepletion)
                      : l10n.noActiveDepletion,
                  align: CrossAxisAlignment.end,
                  valueColor: billingActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ],
            ),
            if (billingActive) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: null,
                  minHeight: 3,
                  backgroundColor: theme.dividerColor.withValues(alpha: 0.3),
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

// ── Small helpers ──

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppIconButton(
      icon: icon,
      onTap: onTap,
      variant: filled
          ? AppIconButtonVariant.filled
          : AppIconButtonVariant.outlined,
      tone: filled ? AppIconButtonTone.primary : AppIconButtonTone.neutral,
    );
  }
}

class _FooterMetric extends StatelessWidget {
  final String label;
  final String value;
  final CrossAxisAlignment align;
  final Color valueColor;

  const _FooterMetric({
    required this.label,
    required this.value,
    required this.align,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
