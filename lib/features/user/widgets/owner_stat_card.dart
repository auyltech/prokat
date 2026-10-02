import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';

class OwnerStatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String firstLabel;
  final String firstValue;
  final String secondLabel;
  final String secondValue;
  final VoidCallback? onTap;

  const OwnerStatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.firstLabel,
    required this.firstValue,
    required this.secondLabel,
    required this.secondValue,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AppCard(
      padding: const EdgeInsets.all(AppDimens.s12$md),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            maxLines: 1,
            softWrap: false,
            style: AppFonts.headingS(context),
          ),
          const SizedBox(height: AppDimens.s08$sm),
          Row(
            spacing: AppDimens.s12$md,
            children: [
              Container(
                width: AppDimens.statCardIconBoxSize,
                height: AppDimens.statCardIconBoxSize,
                decoration: BoxDecoration(
                  border: Border.all(color: colors.card.border),
                  borderRadius: const BorderRadius.all(
                    Radius.circular(AppDimens.r08$md),
                  ),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: AppDimens.statCardIconSize,
                    color: colors.icons.main,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: AppDimens.s04$xs,
                  children: [
                    _MetricLine(label: firstLabel, value: firstValue),
                    _MetricLine(label: secondLabel, value: secondValue),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricLine extends StatelessWidget {
  final String label;
  final String value;

  const _MetricLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      spacing: AppDimens.s08$sm,
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.body16(context).copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
        Text(
          value,
          style: AppFonts.body16SemiBold(context).copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
