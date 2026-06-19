import 'package:flutter/material.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/features/billing/models/time_breakdown.dart';
import 'package:prokat/features/billing/models/transaction_model.dart';
import 'package:prokat/l10n/app_localizations.dart';

class OwnerPaymentTile extends StatelessWidget {
  final TransactionModel transaction;

  const OwnerPaymentTile({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final isTopUp = transaction.type == TransactionType.topup;
    final isConsumption = transaction.type == TransactionType.consumption;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isTopUp
                ? Colors.green[50]
                : isConsumption
                ? Colors.red[50]
                : Colors.grey[100],
            shape: BoxShape.circle,
          ),
          child: Icon(
            isTopUp
                ? Icons.account_balance_wallet_outlined
                : isConsumption
                ? Icons.receipt_long_outlined
                : Icons.payment_outlined,
            size: 24,
            color: isTopUp
                ? Colors.green[800]
                : isConsumption
                ? Colors.red[600]
                : Colors.grey[800],
          ),
        ),
        title: Text(
          getTimeString(transaction.seconds),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          formatDateTime(transaction.createdAt, transaction.createdAt),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: transaction.type == TransactionType.topup
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {},
                    child: Text(
                      l10n.repeat,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }
}
