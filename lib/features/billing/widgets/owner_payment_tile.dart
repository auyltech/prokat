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
    final isGift = transaction.type == TransactionType.freecredit;

    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isTopUp
                ? Colors.green[50]
                : isConsumption
                ? Colors.red[50]
                : isGift
                ? const Color(0xFFF3E8FF)
                : Colors.grey[100],
            shape: BoxShape.circle,
          ),
          child: Icon(
            isTopUp
                ? Icons.account_balance_wallet_outlined
                : isConsumption
                ? Icons.receipt_long_outlined
                : isGift
                ? Icons.card_giftcard_outlined
                : Icons.payment_outlined,
            size: 24,
            color: isTopUp
                ? Colors.green[800]
                : isConsumption
                ? Colors.red[600]
                : isGift
                ? const Color(0xFF7C3AED)
                : Colors.grey[800],
          ),
        ),
        title: Text(
          getTimeString(transaction.seconds, l10n),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          isGift
              ? '${l10n.transactionGift} · ${formatDateTime(transaction.createdAt, transaction.createdAt, locale: l10n.localeName)}'
              : formatDateTime(
                  transaction.createdAt,
                  transaction.createdAt,
                  locale: l10n.localeName,
                ),
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
