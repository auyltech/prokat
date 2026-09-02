import 'package:flutter/material.dart';
import 'package:prokat/features/billing/models/time_breakdown.dart';
import 'package:prokat/l10n/app_localizations.dart';

class BalanceSummaryTile extends StatelessWidget {
  final bool isloading;
  final bool isError;
  final int secondsRemaining;
  final bool hasActiveBurn;
  final VoidCallback onTap;

  const BalanceSummaryTile({
    super.key,
    required this.isloading,
    required this.isError,
    required this.secondsRemaining,
    required this.hasActiveBurn,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // 1. Feature Isolation: Local loading block
    if (isloading) {
      return const SizedBox(
        height: 64,
        child: Center(
          child: SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    // 2. Feature Isolation: Local parsing/network failure view
    if (isError) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.red,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.balanceLoadError,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.shade900,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final timeString = getTimeString(secondsRemaining, l10n);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade100, width: 1.5),
        ),
        child: Row(
          children: [
            // Status Icon Indicator
            Icon(
              hasActiveBurn
                  ? Icons.timelapse_rounded
                  : Icons.account_balance_wallet_rounded,
              color: hasActiveBurn ? Colors.green : theme.colorScheme.primary,
              size: 20,
            ),

            const SizedBox(width: 12),

            // Text values segment
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.remainingTime,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeString,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Forward chevron link
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
